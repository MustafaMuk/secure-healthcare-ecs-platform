locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-github-actions-oidc"
    Purpose = "GitHub Actions workload identity"
  })
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    sid     = "GitHubActionsMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        replace(
          var.github_subject,
          ":ref:${var.github_ref}",
          ":*"
        )
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository"

      values = [
        var.github_repository
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_id"

      values = [
        var.github_repository_id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_owner_id"

      values = [
        var.github_repository_owner_id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:ref"

      values = [
        var.github_ref
      ]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name = "${local.name_prefix}-cd-role"

  description = (
    "Temporary deployment identity for the CareFlow GitHub Actions workflow."
  )

  assume_role_policy = (
    data.aws_iam_policy_document.github_assume_role.json
  )

  max_session_duration = 3600

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-cd-role"
    Purpose = "OIDC authenticated application deployment"
  })
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid    = "AuthenticateToECR"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PublishApplicationImage"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      var.ecr_repository_arn
    ]
  }

  statement {
    sid    = "ManageTaskDefinitionRevisions"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "DeployOnlyCareFlowService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = [
      var.ecs_service_arn
    ]
  }

  statement {
    sid    = "PassOnlyCareFlowTaskRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      var.task_execution_role_arn,
      var.task_role_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name = "${local.name_prefix}-github-deploy-policy"
  role = aws_iam_role.github_deploy.id

  policy = (
    data.aws_iam_policy_document.github_deploy.json
  )
}
