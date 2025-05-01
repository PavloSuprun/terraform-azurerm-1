resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  network_interface_ids           = [azurerm_network_interface.this.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tpl", {
    vm_admin_username          = var.vm_admin_username
    admin_ssh_public_key       = var.admin_ssh_public_key
    sql_connection_string      = var.sql_connection_string
    sql_server_host            = var.sql_server_host
    sql_admin_username         = var.sql_admin_username
    sql_admin_password         = var.sql_admin_password
    sql_database_name          = var.sql_database_name
    ssl_certificate_password   = var.ssl_certificate_password
    ssl_certificate_pfx_base64 = var.ssl_certificate_pfx_base64
    tomcat_unit_file           = indent(6, file("${path.module}/tomcat.service"))
  }))
}
