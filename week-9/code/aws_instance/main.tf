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

data "aws_ami" "latest_amzn2_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=${var.db_endpoint} \
                  -e WORDPRESS_DB_USER=${var.db_username} \
                  -e WORDPRESS_DB_PASSWORD=${var.db_password} \
                  -e WORDPRESS_DB_NAME=${var.db_name} \
                  -p 80:80 ${var.image.name}:${var.image.tag}
              EOF
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt"
  image_id      = data.aws_ami.latest_amzn2_ami.id
  instance_type = var.instance_type

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = var.name_prefix
      }
    )
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this.id]
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "aws_instance" "this" {
  count = 1
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-web-service"
  description = var.description
  tags        = var.tags
}

resource "aws_security_group_rule" "http_ingress" {
  security_group_id = aws_security_group.this.id

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "all_egress" {
  security_group_id = aws_security_group.this.id

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}