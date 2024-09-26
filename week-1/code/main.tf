data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

resource "aws_instance" "this" {
  # Amazon Linux 2 AMI
  ami = "ami-08578967e04feedea"

  # Free Tier: t2.micro 750 hours / month - 12 months
  instance_type = "t2.micro"

  # Useful for demo, wouldn't advise for production workloads
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.this.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d \
                -e WORDPRESS_DB_HOST=${aws_db_instance.this.endpoint} \
                -e WORDPRESS_DB_USER=${aws_db_instance.this.username} \
                -e WORDPRESS_DB_PASSWORD=${aws_db_instance.this.password} \
                -e WORDPRESS_DB_NAME=${aws_db_instance.this.db_name} \
                -p 80:80 ${var.image.name}:${var.image.tag}
              EOF

  tags = {
    Name = var.name_prefix
  }
}

resource "aws_db_instance" "this" {
  identifier        = var.name_prefix # cloud identifier for this database
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  engine            = "mariadb"
  engine_version    = "10.6"
  db_name           = "wordpress" # logical database name

  username               = "admin"
  password               = "yourpassword"
  vpc_security_group_ids = [aws_security_group.mariadb.id]
  skip_final_snapshot    = true
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-web-service"
  description = "Allow all outbound traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere (replace with a specific IP range for better security)
  }

  # Needs to be able to get to docker hub to download images
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_security_group" "mariadb" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }
}
