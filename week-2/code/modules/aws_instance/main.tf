resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = var.user_data

  tags = merge(
    var.tags,
    {
      Name = var.name_prefix
    }
  )
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
