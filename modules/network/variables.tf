variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
  }))
}

variable "nsg_name" {
  type = string
}

variable "allowed_source_ips" {
  type = list(string)
}

variable "domain_name" {
  type = string
}