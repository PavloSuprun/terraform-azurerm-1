data "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_rg
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = var.sql_admin_password_secret_name
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "vm_ssh_private_key" {
  name         = var.vm_ssh_private_key_secret_name
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_certificate" "ssl_certificate" {
  name         = var.ssl_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "ssl_certificate_secret" {
  name         = data.azurerm_key_vault_certificate.ssl_certificate.name
  key_vault_id = data.azurerm_key_vault_certificate.ssl_certificate.key_vault_id
}