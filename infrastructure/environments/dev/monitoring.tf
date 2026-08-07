module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  ecs_cluster_name = (
    module.ecs_service.cluster_name
  )

  ecs_service_name = (
    module.ecs_service.service_name
  )

  database_instance_id = (
    module.database.database_instance_id
  )

  load_balancer_arn_suffix = (
    module.load_balancer.load_balancer_arn_suffix
  )

  target_group_arn_suffix = (
    module.load_balancer.target_group_arn_suffix
  )

  application_log_group_name = (
    module.ecs_service.application_log_group_name
  )
}
