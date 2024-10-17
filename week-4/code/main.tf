terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      environment = "dev"
      project     = "opentofu-foundations"
    }
  }
}

# Module for Database Instance
module "aws_db_instance" {
  source = "./modules/aws_db_instance"

  name_prefix = "week4-db"
  db_name     = "wordpress"
  username    = "admin"
  password    = "yourpassword" # In production, use a secure method for passwords

  tags = {
    Owner = "YourName"
  }
}

# Module for EC2 Instance
module "aws_instance" {
  source = "./modules/aws_instance"

  name_prefix   = "week4-instance"
  instance_type = "t2.micro"

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
