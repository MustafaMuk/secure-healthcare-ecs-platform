module "private_endpoints" {
  source = "../../modules/private-endpoints"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_id = module.networking.vpc_id

  application_subnet_ids = (
    module.networking.application_subnet_ids
  )

  application_route_table_ids = (
    module.networking.application_route_table_ids
  )

  application_security_group_id = (
    module.security.application_security_group_id
  )

  endpoint_security_group_id = (
    module.security.vpc_endpoint_security_group_id
  )
}
