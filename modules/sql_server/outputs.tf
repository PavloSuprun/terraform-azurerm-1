output "sql_database_name" {
  value = azurerm_mssql_database.primary_db.name
}

output "sql_server_failover_group_name" {
  value = azurerm_mssql_failover_group.this.name
}

output "jdbc_connection_string" {
  value = "jdbc:sqlserver://${azurerm_mssql_failover_group.this.name}.database.windows.net:1433;database=${azurerm_mssql_database.primary_db.name};user=${var.sql_admin_username}@${azurerm_mssql_server.primary.name};password=${var.sql_admin_password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
  sensitive = true
}

