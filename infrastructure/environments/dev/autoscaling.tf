module "ecs_autoscaling" {
  source = "../../modules/ecs-autoscaling"

  project_name = var.project_name
  environment  = var.environment

  cluster_name = module.ecs_service.cluster_name
  service_name = module.ecs_service.service_name

  # Cost-conscious development limits.
  minimum_capacity = 1
  maximum_capacity = 2

  cpu_target    = 60
  memory_target = 70
}
