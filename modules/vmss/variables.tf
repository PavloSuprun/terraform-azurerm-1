variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "admin_ssh_public_key" {
  type = string
}

variable "shared_image_id" {
  type = string
}

variable "vmss_lb_public_ip_address_id" {
  type = string
}

variable "frontend_ip_configuration_name" {
  type = string
}
