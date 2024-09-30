data "aws_vpc" "default" {
  filter {
    name = "isDefault"
    values = ["true"]
  }
}

resource "aws_db_instance" "this" {
  identifier              = var.name_prefix
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  engine                  = var.engine
  engine_version          = var.engine_version
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  vpc_security_group_ids  = [aws_security_group.this.id]
  skip_final_snapshot     = true

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

