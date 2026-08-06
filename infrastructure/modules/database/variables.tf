variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "database_subnet_ids" {
  description = "Isolated subnet IDs used by RDS."
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_ids) == 2
    error_message = "Exactly two database subnets must be supplied."
  }
}

variable "database_security_group_id" {
  description = "Security group that permits PostgreSQL only from ECS."
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "careflow"
}

variable "master_username" {
  description = "Master database username. Password is managed by RDS."
  type        = string
  default     = "careflow_admin"
}

variable "instance_class" {
  description = "RDS instance class used by the development environment."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated PostgreSQL storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "PostgreSQL gp3 storage must be at least 20 GiB."
  }
}

variable "backup_retention_days" {
  description = "Number of days that automated backups are retained."
  type        = number
  default     = 7

  validation {
    condition = (
      var.backup_retention_days >= 1 &&
      var.backup_retention_days <= 35
    )

    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "deletion_protection" {
  description = "Prevent accidental database deletion."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when destroying the development DB."
  type        = bool
  default     = true
}
