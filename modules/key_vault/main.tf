data "azurerm_key_vault" "this" {
  name                = "pavsupr-kv"
  resource_group_name = "key-vault"
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "vm_ssh_private_key" {
  name         = "vm-ssh-private-key"
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_certificate" "ssl_certificate" {
  name         = "my-azure-web-app-cert"
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "ssl_certificate_secret" {
  name         = data.azurerm_key_vault_certificate.ssl_certificate.name
  key_vault_id = data.azurerm_key_vault_certificate.ssl_certificate.key_vault_id
}