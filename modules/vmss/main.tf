resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                            = "todo-app-vmss"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  sku                             = "Standard_B1s"
  instances                       = 1
  source_image_id                 = var.shared_image_id
  upgrade_mode                    = "Manual"
  overprovision                   = false
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.admin_ssh_public_key
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "vmss-ipconfig"
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.this.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.this.id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_monitor_autoscale_setting" "cpu_scale" {
  name                = "vmss-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    name = "default"
    capacity {
      minimum = "1"
      maximum = "3"
      default = "1"
    }

    rule {
      metric_trigger {
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 12
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        metric_name        = "Percentage CPU"
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThanOrEqual"
        threshold          = 5
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_lb" "this" {
  name                = "vmss-load-balancer"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = var.vmss_lb_public_ip_address_id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "vmss-backend-pool"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 8080
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "https_probe" {
  name                = "https-probe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Https"
  port                = 8443
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

resource "azurerm_lb_rule" "https_rule" {
  name                           = "https-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.https_probe.id
}

resource "azurerm_lb_nat_pool" "this" {
  name                           = "ssh-nat-pool"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this.id
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  protocol                       = "Tcp"
  frontend_port_start            = 50001
  frontend_port_end              = 50003
  backend_port                   = 22
}

