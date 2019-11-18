variable access_key {}
variable secret_key {}
variable region {}
variable key_name {}
variable db_root_user {}
variable db_root_pass {}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 80
}

variable "ssh_port" {
  default = 22
}

