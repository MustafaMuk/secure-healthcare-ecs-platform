module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name = var.project_name
  environment  = var.environment

  origin_domain_name = (
    module.load_balancer.load_balancer_dns_name
  )
}
