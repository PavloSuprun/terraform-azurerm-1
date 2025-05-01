resource "azurerm_image" "this" {
  name                      = "todo-app-golden-image"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  source_virtual_machine_id = var.vm_id

  os_disk {
    os_type      = "Linux"
    caching      = "ReadWrite"
    storage_type = "Standard_LRS"
  }
}

resource "azurerm_shared_image_gallery" "this" {
  name                = "todoGallery"
  resource_group_name = var.resource_group_name
  location            = var.location
  description         = "Shared Image Gallery for VMSS golden images"
}

resource "azurerm_shared_image" "this" {
  name                = azurerm_image.this.name
  gallery_name        = azurerm_shared_image_gallery.this.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  hyper_v_generation  = "V1"
  architecture        = "x64"

  identifier {
    publisher = "pavsupr"
    offer     = "todo-app"
    sku       = "v1"
  }
}

resource "azurerm_shared_image_version" "this" {
  name                = "1.0.0"
  gallery_name        = azurerm_shared_image_gallery.this.name
  image_name          = azurerm_shared_image.this.name
  resource_group_name = var.resource_group_name
  location            = var.location
  managed_image_id    = azurerm_image.this.id

  target_region {
    name                   = var.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }
}