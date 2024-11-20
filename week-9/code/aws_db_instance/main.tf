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

data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

resource "aws_db_instance" "this" {
  identifier             = var.name_prefix
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  vpc_security_group_ids = [aws_security_group.this.id]
  skip_final_snapshot    = true

  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "vpc" {
  security_group_id = aws_security_group.this.id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  cidr_ipv4   = data.aws_vpc.default.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
