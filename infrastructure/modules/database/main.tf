locals {
  identifier = "${var.project_name}-${var.environment}-postgresql"

  common_tags = {
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "Terraform"
    DataClassification = "synthetic-only"
  }
}

resource "aws_db_subnet_group" "this" {
  name        = "${local.identifier}-subnets"
  description = "Isolated database subnets for CareFlow PostgreSQL."
  subnet_ids  = var.database_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.identifier}-subnets"
    Tier = "isolated-database"
  })
}

resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.identifier}/postgresql"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name    = "${local.identifier}-postgresql-logs"
    Purpose = "PostgreSQL operational logging"
  })
}

resource "aws_cloudwatch_log_group" "upgrade" {
  name              = "/aws/rds/instance/${local.identifier}/upgrade"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name    = "${local.identifier}-upgrade-logs"
    Purpose = "PostgreSQL upgrade logging"
  })
}

resource "aws_db_instance" "this" {
  identifier = local.identifier

  engine         = "postgres"
  engine_version = "17.10"
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  port     = 5432

  manage_master_user_password = true

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    var.database_security_group_id
  ]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = var.backup_retention_days
  backup_window           = "02:00-02:30"
  maintenance_window      = "Sun:03:00-Sun:04:00"

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  delete_automated_backups = true
  copy_tags_to_snapshot    = true

  performance_insights_enabled = false
  monitoring_interval          = 0

  depends_on = [
    aws_cloudwatch_log_group.postgresql,
    aws_cloudwatch_log_group.upgrade
  ]

  tags = merge(local.common_tags, {
    Name    = local.identifier
    Tier    = "isolated-database"
    Service = "PostgreSQL"
  })
}
