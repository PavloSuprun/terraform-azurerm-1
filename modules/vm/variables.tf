variable "vm_name" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "public_ip_address" {
  type = string
}

variable "public_ip_id" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "admin_ssh_public_key" {
  type = string
}

variable "admin_ssh_private_key" {
  type = string
}

variable "sql_connection_string" {
  type = string
}

variable "sql_server_host" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "sql_admin_username" {
  type = string
}

variable "sql_admin_password" {
  type = string
}

variable "ssl_certificate_pfx_base64" {
  type = string
}

variable "ssl_certificate_password" {
  type = string
  default = ""
}
