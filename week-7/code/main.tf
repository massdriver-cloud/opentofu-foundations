terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }

   backend "s3" {
    bucket         = "opentofu-foundations-opentofu-state-yc5m" # your bucket name here
    key            = "wordpress/terraform.tfstate"              # Change the path per root module
    dynamodb_table = "opentofu-foundations-opentofu-locks-yc5m" # your bucket name here
    region         = "us-west-2"
   }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      environment = local.environment 
      project     = "opentofu-foundations"
    }
  }
}

locals {
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  environment_name_segment = terraform.workspace == "default" ? "" : "${terraform.workspace}-"
}

variable "image" {
  type = object({
    name = string
    tag  = string
  })

  default = {
    name = "wordpress"
    tag  = "latest"
  }
}

variable "name_prefix" {
  type = string
}

variable wordpress_instance_type {
  type = string
}

variable db_instance_class {
  type = string
}

# Module for Database Instance
module "aws_db_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_db_instance?ref=main"

  name_prefix = "${var.name_prefix}-${local.environment_name_segment}db"
  db_name     = "wordpress"
  username    = "admin"
  password    = "yourpassword" # In production, use a secure method for passwords
  instance_class = var.db_instance_class

  tags = {
    Owner = "YourName"
  }
}

# Module for EC2 Instance
module "aws_instance" {
  source = "github.com/massdriver-modules/otf-shared-modules//modules/aws_instance?ref=main"

  name_prefix   = "${var.name_prefix}-${local.environment_name_segment}instance"
  instance_type = var.wordpress_instance_type 

  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=${module.aws_db_instance.endpoint} \
                  -e WORDPRESS_DB_USER=${module.aws_db_instance.username} \
                  -e WORDPRESS_DB_PASSWORD=${module.aws_db_instance.password} \
                  -e WORDPRESS_DB_NAME=${module.aws_db_instance.db_name} \
                  -p 80:80 ${var.image.name}:${var.image.tag}
              EOF

  tags = {
    Owner = "YourName"
  }
}
