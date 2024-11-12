variable "name_prefix" {
  description = "Name prefix for state-related resources"
  type        = string
}

module "state" {
  source      = "github.com/massdriver-modules/otf-shared-modules//modules/opentofu_state_backend?ref=main"
  name_prefix = var.name_prefix
}

output "usage" {
  description = "Example state backend configuration"
  value       = module.state.usage
}
