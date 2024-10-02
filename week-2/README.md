# Week 2 Course: Modular Infrastructure with OpenTofu

**Duration:** 1 hour

## Introduction

Welcome to week two of the [OpenTofu workshop](https://www.massdriver.cloud/blogs/opentofu-foundations---a-free-weekly-workshop-to-build-your-iac-skills)! This week, we'll dive into the concept of modular infrastructure using OpenTofu. Modules are a powerful way to organize your code, promote reusability, and enforce best practices in Infrastructure as Code (IaC). By the end of this session, you'll be able to create your own modules, use existing ones, and apply best practices for modular infrastructure design.

**Important**: This session builds upon concepts from Week 1, where we created an EC2 instance running WordPress connected to a MariaDB database using `aws_db_instance`. If you haven't completed the [Week 1 module](https://github.com/massdriver-cloud/opentofu-foundations/tree/main/week-1), we recommend reviewing it before proceeding.

## Course Objectives

- Understand what modules are and why they are important.
- Learn how to create reusable modules.
- Refactor the Week 1 code into modules.
- Import and use modules in your configurations.
- Apply best practices for modular infrastructure design.

## Key Commands

Commands you'll use to manage modules and your infrastructure:

- `tofu init`
- `tofu plan`
- `tofu apply`
- `tofu destroy`

## Prerequisites

- Completion of [Week 1](https://github.com/massdriver-cloud/opentofu-foundations/tree/main/week-1) or equivalent knowledge.
- An AWS Account.
- [OpenTofu CLI](https://opentofu.org/docs/intro/install/) installed.

## Walkthrough

### 1. Understanding Modules

**What is a module?**

In OpenTofu, a **module** is a container for multiple resources that are used together. Modules are the basic building blocks of your infrastructure, allowing you to group resources logically and reuse code across different configurations.

**Why use modules?**

- **Reusability**: Write code once and use it in multiple places.
- **Maintainability**: Easier to manage and update code.
- **Abstraction**: Simplify complex configurations.
- **Collaboration**: Share modules within teams or the community.

### 2. Modularizing the EC2 Instance and Database

In Week 1, we created an EC2 instance (`aws_instance`) running WordPress and an AWS DB instance (`aws_db_instance`) for the MariaDB database. Now, we'll create modules for both the EC2 instance and the database to promote reusability and better organization.

#### Step 2.1: Create Module Directory Structure

Create directories for your modules:

```sh
mkdir -p modules/aws_instance
mkdir -p modules/aws_db_instance
```

#### Step 2.2: Create the EC2 Instance Module

Navigate to the `aws_instance` module directory:

```sh
cd modules/aws_instance
touch {main.tf,variables.tf,outputs.tf}
```

##### **`main.tf`**

```hcl
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
```

##### **`variables.tf`**

```hcl
variable "name_prefix" {
  description = "Name prefix for all the resources"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = "OpenTofu Foundations internet access for EC2 instance"
}

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-08578967e04feedea" # Amazon Linux 2 AMI

  validation {
    condition     = length(regex("^ami-[0-9a-z]{17}$", var.ami)) > 0
    error_message = "AMI must start with \"ami-\"."
  }
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "Allowed instance types are \"t2.micro\", \"t3.micro\"."
  }
}

variable "user_data" {
  description = "User data script to initialize the instance"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

```

##### **`outputs.tf`**

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.this.id
}
```

#### Step 2.3: Create the Database Module

Navigate to the `aws_db_instance` module directory:

```sh
cd ../aws_db_instance
touch {main.tf,variables.tf,outputs.tf}
```

##### **`main.tf`**

```hcl
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

```

##### **`variables.tf`**

```hcl
variable "name_prefix" {
  description = "Identifier for the database instance"
  type        = string
}

variable "instance_class" {
  description = "Instance class for the DB instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mariadb"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "10.6"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "username" {
  description = "Master username for the database"
  type        = string
}

variable "password" {
  description = "Master password for the database"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the database instance"
  type        = map(string)
  default     = {}
}
```

##### **`outputs.tf`**

```hcl
output "endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.this.endpoint
}

output "username" {
  description = "Database master username"
  value       = aws_db_instance.this.username
}

output "password" {
  description = "Database master password"
  value       = aws_db_instance.this.password
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.this.id
}
```

#### Step 2.4: Return to Root Directory

Navigate back to the root directory:

```sh
cd ../../
```

### 3. Using the Modules in Your Configuration

Now that we've created modules for the `aws_instance` and `aws_db_instance`, let's use them in our main configuration.

#### Step 3.1: Set Up the Root Configuration

Create or modify `main.tf` in the root directory:

**`main.tf`**:

```hcl
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

# Data source to get the default VPC
data "aws_vpc" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

# Module for Database Instance
module "aws_db_instance" {
  source = "./modules/aws_db_instance"

  name_prefix = "week2-db"
  db_name     = "wordpress"
  username    = "admin"
  password    = "yourpassword"  # In production, use a secure method for passwords

  ingress_cidr_blocks = [data.aws_vpc.default.cidr_block]

  tags = {
    Owner = "YourName"
  }
}

# Module for EC2 Instance
module "aws_instance" {
  source = "./modules/aws_instance"

  name_prefix   = "week2-instance"
  ami           = "ami-08578967e04feedea" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  user_data     = <<-EOF
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
```

**Note**: We've aligned the resource names with those in Week 1, using `aws_instance` and `aws_db_instance`. We are also using `data "aws_vpc" "default"` to retrieve the default VPC's CIDR block.

#### Step 3.2: Create `outputs.tf` to Access Module Outputs

**`outputs.tf`**:

```hcl
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.aws_instance.public_ip
}

output "db_endpoint" {
  description = "Endpoint of the database instance"
  value       = module.aws_db_instance.endpoint
}
```

### 4. Initialize and Apply the Configuration

#### Step 4.1: Initialize OpenTofu

Run:

```sh
tofu init
```

This will download the AWS provider and initialize the modules.

#### Step 4.2: Plan the Deployment

Run:

```sh
tofu plan
```

Review the plan to ensure it matches your expectations. You should see resources for the EC2 instance, database instance, and their associated security groups being created.

#### Step 4.3: Apply the Configuration

Run:

```sh
tofu apply --auto-approve
```

This will create the resources as defined in your configuration. Note that the database instance may take several minutes to become available.

### 5. Verify the Deployment

#### Step 5.1: Retrieve Outputs

Run:

```sh
tofu output
```

You should see the public IP address of your EC2 instance and the endpoint of your database instance.

Example output:

```
instance_public_ip = "54.123.45.67"
db_endpoint        = "week2-db.abcdefghij.us-west-2.rds.amazonaws.com"
```

#### Step 5.2: Test the Instance

Open a web browser and navigate to `http://<instance_public_ip>`. You should see the WordPress setup screen.

### 6. Best Practices for Module Design

- **Version Control**: Use versioning for your modules to manage changes and ensure stability.
- **Documentation**: Provide clear documentation for inputs, outputs, and usage instructions.
- **Minimal Exposure**: Only expose necessary variables to keep modules simple and user-friendly.
- **Default Values**: Provide sensible defaults for variables where appropriate.
- **Consistent Naming**: Use consistent naming conventions for resources and variables.
- **Outputs**: Expose useful outputs to make the module more flexible.
- **Error Handling**: Use validations to catch incorrect variable values.

### 7. Cleaning Up

Don't forget to destroy your infrastructure to avoid unnecessary charges:

```sh
tofu destroy -auto-approve
```

## Conclusion

In this module, we expanded on the infrastructure from Week 1 by modularizing the `aws_instance` and `aws_db_instance` resources. We learned how to create reusable modules, manage dependencies between them, and apply best practices for module design.

**Key Takeaways**:

- **Modules**: Created custom modules for the `aws_instance` and `aws_db_instance`.
- **Variables and Outputs**: Defined inputs and outputs to make modules flexible and reusable.
- **Inter-Module Communication**: Used outputs from one module as inputs to another.
- **Best Practices**: Applied best practices in module design for maintainability and collaboration.

## Challenges

Want to keep practicing before Week 3? Here are some challenges:

1. **Enhance the Database Module**: Add [variables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) to configure more database options, such as backup retention, multi-AZ deployments, or storage type. Add [validations](https://opentofu.org/docs/language/expressions/custom-conditions/) to some of the variables for the database `variables.tf` (`instance_class`, `allocated_storage`, `engine`, `engine_version`). Set `password` in `aws_db_instance/variables.tf` to [sensitive](https://opentofu.org/docs/v1.7/language/values/variables/#suppressing-values-in-cli-output).
2. **Parameterize Security Groups**: Modify the security group definitions for `aws_instance` and `aws_db_instance` to accept lists of ports and protocols as variables.
3. **Use AWS Secrets Manager**: Store the database password in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) (or [SSM](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)) and retrieve it in your configuration. 
4. **Create a VPC Module**: Create a module for VPC components like subnets, route tables, and internet gateways.
5. **Implement Module Versioning**: [Tag your modules](https://opentofu.org/docs/language/modules/sources/) with versions and test upgrading between versions:

```terraform
module "vpc" {
  source = "github.com/my-repo/my-module?ref=sha1234"
}
```

---

**Happy coding!** See you in Week 3, where we'll explore functions and control structures in OpenTofu.
