data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  selected_availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    2
  )
}

module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = "10.42.0.0/16"

  availability_zones = local.selected_availability_zones

  public_subnet_cidrs = [
    "10.42.0.0/24",
    "10.42.1.0/24"
  ]

  application_subnet_cidrs = [
    "10.42.10.0/24",
    "10.42.11.0/24"
  ]

  database_subnet_cidrs = [
    "10.42.20.0/24",
    "10.42.21.0/24"
  ]
}
