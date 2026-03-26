output "imported_resources_summary" {
  description = "Resumo dos recursos importados"
  value = {
    environment = var.environment
    region      = var.aws_region
    project     = var.project_name
  }
}
