terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }

  backend "s3" {
    bucket         = "your-bucket-here"
    key            = "my_state/terraform.tfstate"
    dynamodb_table = "your-dynamodb-table-here"
    region         = "us-west-2"
    encrypt        = true
  }
}

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
