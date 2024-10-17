# Week 4 Course: Advanced OpenTofu Resource Management

**Duration:** 1 hour

## Introduction

Welcome to week four of the [OpenTofu workshop](https://www.massdriver.cloud/blogs/opentofu-foundations---a-free-weekly-workshop-to-build-your-iac-skills)! This week, we'll dive into some of the advanced strategies for managing OpenTofu resources, including data sources, loops, conditionals, dynamic blocks, and lifecycle rules.

## Prerequisites

Before starting, ensure you have the following set up:
- Terraform/OpenTofu installed: [Install OpenTofu](https://opentofu.com/getting-started)
- Access to an AWS account (or any cloud provider).
- Basic knowledge of Terraform configuration language (HCL).
- Completed the previous foundation course.

## Topics Covered

- Data Sources
- Loops with `count` and `for_each`
- Dynamic Blocks
- Conditional Resources
- Conditional Expressions
- Lifecycle Rules

## Structure

This course includes hands-on examples and code snippets that you can follow along with. You’ll be working with a provided OpenTofu configuration, which you can find in this repository.


### 1. Data Sources
Data sources allow you to query existing infrastructure or external resources to retrieve information dynamically. Let's update the `aws_instance` module to use a data source to fetch the latest AMI.

**Example:**

```hcl
data "aws_ami" "latest_amzn2_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
}
```

In this example, the data source is used to retrieve the latest Amazon Linux AMI, which is then used in the aws_instance resource.


### 2. Loops with count and for_each
You can use count or for_each to create multiple resources dynamically. First let's use a count to manage the number of `aws_instance` resources.

**Example with count:**

```hcl
resource "aws_instance" "this" {
  count = 1
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = [aws_instance.this.*.id]
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = [aws_instance.this.*.public_ip]
}
```

Now let's update the `aws_instance` module to use a `for_each` to manage the security group rules.

**Example with for_each:**

```hcl
locals {
  security_group_rules = {
    "HTTP": {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    "Allow all outbound traffic": {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-web-service"
  description = var.description

  tags = var.tags
}

resource "aws_security_group_rule" "this" {
  for_each = local.security_group_rules
  description       = each.key
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.this.id
}
```

### 3. Dynamic Blocks
Dynamic blocks allow you to create 0 to N number of blocks within a single resource. For this to work, the block must be able to be specified multiple times. Let's update the ingress rules of the database security group to use a dynamic block declaration to manage ingress rules.

**Example:**

```hcl
variable "ingress_cidr_blocks" {
  description = "CIDR blocks to allow access to the database"
  type        = list(string)
  default     = []
}

locals {
  allow_cidr_blocks = concat([data.aws_vpc.default.cidr_block], var.ingress_cidr_blocks)
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-mariadb"
  description = "Allow access to MariaDB"

  dynamic "ingress" {
    for_each = local.allow_cidr_blocks

    content {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
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

### 4. Conditional Resources

Conditional resources allow you to enable or disable certain infrastructure components based on input variables. Let's conditionally create an SSH key and add a port opening for SSH in the `aws_instance` module.

**Example:**
```hcl
variable "enable_ssh" {
  type    = bool
  default = true
}

resource "tls_private_key" "ssh" {
  count = var.enable_ssh ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  count = var.enable_ssh ? 1 : 0
  key_name   = "${var.name_prefix}-ssh"
  public_key = tls_private_key.ssh[0].public_key_openssh
}

resource "aws_security_group_rule" "ssh" {
  count = var.enable_ssh ? 1 : 0
  description       = "enable SSH access"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}
```

In this example, the `tls_private_key`, `aws_key_pair` and `aws_security_group_rule` resources are created only if `var.enable_ssh` is set to true.

### 5. Conditional Expressions
Conditional expressions allow you to modify configuration behavior based on certain conditions. We need to update the `launch_template` to use the SSH key if `var.enable_ssh` is true.

**Example:**

```hcl
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt"
  image_id      = data.aws_ami.latest_amzn2_ami.id
  instance_type = var.instance_type

  user_data = base64encode(var.user_data)

  key_name = var.enable_ssh ? aws_key_pair.ssh[0].key_name : null

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
```

We need to make sure we leave the SSH key set to `null` if `var.enable_ssh` is `false`.


### 6. Lifecycle Rules
Lifecycle rules help manage resource behavior during create, update, and delete operations. There are 4 different rules:
* `create_before_destroy`: Ensures that a new resource is created before an old one is destroyed, to prevent downtime during replacements.
* `prevent_destroy`: Protects a resource from being accidentally destroyed during operations, ensuring it remains intact unless explicitly allowed.
* `ignore_changes`: Tells Terraform/OpenTofu to ignore certain specified attributes when updating resources, allowing changes to be made outside of the configuration without causing updates.
* `replace_triggered_by`: Forces the replacement of a resource if a specified dependent resource or attribute changes, even if the resource itself remains unchanged.

**Example:**

```hcl
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

  lifecycle {
    prevent_destroy = true
  }
}
```

In this example, the prevent_destroy rule ensures that the database instance cannot be accidentally destroyed.

### 7. Cleaning Up

Don't forget to destroy your infrastructure to avoid unnecessary charges. You'll need to remove the lifecycle `prevent_destroy` on the database to successfully destroy:

```sh
tofu destroy
```

## Conclusion

This week’s course covered advanced techniques in managing OpenTofu resources, emphasizing flexibility and efficiency in infrastructure configurations.

**Key Takeaways**:

- **Data Sources**: Use data sources to dynamically fetch configuration of existing cloud resources.
- **Loops**: Use `count` and `for_each` to create multiple instances of a resource.
- **Dynamic Blocks**: Use dynamic blocks if you need to create multiple blocks in a single resource.
- **Conditionals**: Use `count` with a boolean to conditionally create resources.
- **Lifecycle Rules**: Apply lifecycle rules to control how resources are managed during updates and replacements.


## Challenges

Want to keep practicing before Week 5? Here are some challenges:

1. **SSH into an Instance**: Use the SSH key to access one of the web instances.
2. **Use an Autoscaling Group**: Instead of managing the EC2 instances with a `count` convert it to an [AWS Autoscaling Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).
3. **Change Security Group Rules**: Update your security group rules to use the recommended [`aws_vpc_security_group_ingress_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) and [`aws_vpc_security_group_gress_rule`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule).
4. **Improve Database Security**: Instead of giving database access to the entire VPC, only give access to the security group of the EC2 instance. Even better, add a conditional to the database module that, only if enabled, will grant access to the entire VPC.
5. **Create a Load Balancer**: Place a load balancer in front of the EC2 instance autoscaling group. NOTE: elastic load balancers do not have a free tier. This will incur costs in your AWS account.

**Happy coding!** See you in Week 5, where we'll explore CI/CD in OpenTofu.