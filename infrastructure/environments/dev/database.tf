module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment

  database_subnet_ids = (
    module.networking.database_subnet_ids
  )

  database_security_group_id = (
    module.security.database_security_group_id
  )

  database_name   = "careflow"
  master_username = "careflow_admin"
  instance_class  = "db.t4g.micro"

  allocated_storage     = 20
  backup_retention_days = 1

  # Development settings permit complete teardown after evidence collection.
  deletion_protection = false
  skip_final_snapshot = true
}
