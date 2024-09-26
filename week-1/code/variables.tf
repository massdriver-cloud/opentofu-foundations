
variable "name_prefix" {
  type        = string
  description = "A name prefix for all resources created by this module."
}

variable "image" {
  type = object({
    name = string
    tag  = string
  })

  description = "Docker image to run in the EC2 instance."
  default = {
    name = "wordpress"
    tag  = "latest"
  }
}

# If you want to connect to the database, you can add your IP address here and run the following command:
# Note: the endpoint output is the host:port ... you will need to remove the port
# docker run -it --rm mariadb mariadb -u admin -p --skip-ssl -h <RDS_HOSTNAME>
variable "enable_public_mariadb_access" {
  description = "A list of CIDR blocks to permit public MariaDB access. Set to your IP CIDR block to enable (https://www.whatismyip.com/)"
  type        = list(string)
  default     = []
}
