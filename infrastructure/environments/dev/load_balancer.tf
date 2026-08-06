module "load_balancer" {
  source = "../../modules/load-balancer"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  public_subnet_ids = (
    module.networking.public_subnet_ids
  )

  load_balancer_security_group_id = (
    module.security.load_balancer_security_group_id
  )

  application_port  = 3000
  health_check_path = "/health/ready"
}
