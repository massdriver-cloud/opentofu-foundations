resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt"
  image_id      = var.ami
  instance_type = var.instance_type

  user_data = base64encode(var.user_data)

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
}

resource "aws_instance" "this" {
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-web-service"
  description = var.description

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
