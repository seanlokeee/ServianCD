variable "name" {
  type    = string
  default = "servian-app"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "public_key" {
  type = string
}

variable "instance_count" {
  default = 1
}

variable "db_username" {
  default = "postgres"
}

variable "db_password" {
  default = "password"
}

variable "db_name" {
  default = "serviandb"
}

variable "db_port" {
  default = 5432
}




