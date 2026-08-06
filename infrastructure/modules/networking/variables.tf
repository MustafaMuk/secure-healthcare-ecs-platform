variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used by the platform."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two Availability Zones must be supplied."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public load-balancer subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs must be supplied."
  }
}

variable "application_subnet_cidrs" {
  description = "CIDR blocks for private ECS application subnets."
  type        = list(string)

  validation {
    condition     = length(var.application_subnet_cidrs) == 2
    error_message = "Exactly two application subnet CIDRs must be supplied."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for isolated database subnets."
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_cidrs) == 2
    error_message = "Exactly two database subnet CIDRs must be supplied."
  }
}
