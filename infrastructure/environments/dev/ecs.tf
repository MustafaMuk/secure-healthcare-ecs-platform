data "aws_ecr_image" "application_release" {
  repository_name = (
    module.container_registry.repository_name
  )

  image_tag = var.application_image_tag
}

module "ecs_service" {
  source = "../../modules/ecs-service"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  application_subnet_ids = (
    module.networking.application_subnet_ids
  )

  application_security_group_id = (
    module.security.application_security_group_id
  )

  target_group_arn = (
    module.load_balancer.target_group_arn
  )

  application_image_uri = format(
    "%s@%s",
    module.container_registry.repository_url,
    data.aws_ecr_image.application_release.image_digest
  )

  application_version = var.application_image_tag

  database_host = module.database.database_address
  database_port = module.database.database_port
  database_name = module.database.database_name

  database_secret_arn = (
    module.database.master_user_secret_arn
  )

  application_port = 3000
}
