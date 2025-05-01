output "sql_admin_password" {
  value     = data.azurerm_key_vault_secret.sql_admin_password.value
  sensitive = true
}

output "vm_ssh_private_key" {
  value     = data.azurerm_key_vault_secret.vm_ssh_private_key.value
  sensitive = true
}

output "ssl_certificate_pfx_base64" {
  value     = data.azurerm_key_vault_secret.ssl_certificate_secret.value
  sensitive = true
}
