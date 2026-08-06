module "container_registry" {
  source = "../../modules/container-registry"

  project_name = var.project_name
  environment  = var.environment

  # Development-only setting so the environment can be destroyed
  # after evidence collection, even when the repository has images.
  force_delete = true

  retained_image_count = 15
}
