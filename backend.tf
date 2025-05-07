# terraform {
#   backend "local" {}
# }

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-task"
    storage_account_name = "tfstatetodoapp12345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}