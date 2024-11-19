variable "name_prefix" {
  description = "Name prefix for all the resources"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
  default     = "OpenTofu Foundations internet access for EC2 instance"
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

variable "db_endpoint" {
  description = "Endpoint of the RDS instance"
  type        = string
}

variable "db_username" {
  description = "Username to connect to the RDS instance"
  type        = string
}

variable "db_password" {
  description = "Password to connect to the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the database in the RDS instance"
  type        = string
}

variable "image" {
  description = "Docker image to run on the EC2 instance"
  type = object({
    name = string
    tag  = string
  })

  default = {
    name = "wordpress"
    tag  = "latest"
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}