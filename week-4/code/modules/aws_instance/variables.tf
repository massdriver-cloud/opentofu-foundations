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

