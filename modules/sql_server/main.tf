resource "azurerm_mssql_server" "primary" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "primary_db" {
  name                 = var.sql_database_name
  server_id            = azurerm_mssql_server.primary.id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  sku_name             = "Basic"
  storage_account_type = "Local"
}

resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.primary.id
  start_ip_address = var.allowed_ip_range_start
  end_ip_address   = var.allowed_ip_range_end
}

resource "azurerm_mssql_firewall_rule" "allow_vm_ip" {
  name             = "AllowVMIP"
  server_id        = azurerm_mssql_server.primary.id
  start_ip_address = var.vm_ip_to_allow
  end_ip_address   = var.vm_ip_to_allow
}

resource "azurerm_mssql_firewall_rule" "allow_vmss_lb_ip" {
  name             = "AllowVMSSLBIP"
  server_id        = azurerm_mssql_server.primary.id
  start_ip_address = var.vmss_lb_ip_to_allow
  end_ip_address   = var.vmss_lb_ip_to_allow
}

resource "azurerm_mssql_server" "secondary" {
  name                         = "${var.sql_server_name}-secondary"
  resource_group_name          = var.resource_group_name
  location                     = var.secondary_location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_failover_group" "this" {
  name      = "${var.sql_server_name}-failover-group"
  server_id = azurerm_mssql_server.primary.id
  databases = [azurerm_mssql_database.primary_db.id]

  partner_server {
    id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 80
  }
}