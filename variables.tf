variable "subscription_id" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "allowed_source_ips" {
  type = list(string)
}

variable "allowed_ip_range_start" {
  type = string
}

variable "allowed_ip_range_end" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "sql_admin_username" {
  type = string
}

variable "admin_ssh_public_key" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_rg" {
  type = string
}

variable "sql_admin_password_secret_name" {
  type = string
}

variable "vm_ssh_private_key_secret_name" {
  type = string
}

variable "ssl_certificate_secret_name" {
  type = string
}

variable "domain_name" {
  type = string
}
