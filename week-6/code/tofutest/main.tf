variable name {
  type        = string
  default = ""
}

variable names {
  type        = list(string)
  default = [] 
}

locals {
    name = var.name == "" ? "User" : trimspace(var.name)
}

data "local_file" "main" {
  filename = "file.txt"
}

resource random_pet "multiple" {
    count = length(var.names)
    prefix = "abcd_"
}