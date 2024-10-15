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

