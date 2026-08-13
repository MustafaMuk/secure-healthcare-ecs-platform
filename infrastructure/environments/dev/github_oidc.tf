module "github_oidc" {
  source = "../../modules/github-oidc"

  project_name = var.project_name
  environment  = var.environment

  github_subject = (
    "repo:MustafaMuk@190411277/secure-healthcare-ecs-platform@1324415864:ref:refs/heads/main"
  )

  github_repository = (
    "MustafaMuk/secure-healthcare-ecs-platform"
  )

  github_repository_id       = "1324415864"
  github_repository_owner_id = "190411277"
  github_ref                 = "refs/heads/main"

  ecr_repository_arn = (
    module.container_registry.repository_arn
  )

  ecs_service_arn = (
    module.ecs_service.service_arn
  )

  task_execution_role_arn = (
    module.ecs_service.task_execution_role_arn
  )

  task_role_arn = (
    module.ecs_service.task_role_arn
  )
}
