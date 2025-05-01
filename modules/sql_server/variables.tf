variable "location" {
  type = string
}

variable "secondary_location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "sql_admin_username" {
  type = string
}

variable "sql_admin_password" {
  type = string
}

variable "sql_database_name" {
  type = string
}

variable "allowed_ip_range_start" {
  type = string
}

variable "allowed_ip_range_end" {
  type = string
}

variable "vm_ip_to_allow" {
  type = string
}

variable "vmss_lb_ip_to_allow" {
  type = string
}