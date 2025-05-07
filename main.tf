module "key_vault" {
  source                         = "./modules/key_vault"
  key_vault_rg                   = var.key_vault_rg
  key_vault_name                 = var.key_vault_name
  sql_admin_password_secret_name = var.sql_admin_password_secret_name
  vm_ssh_private_key_secret_name = var.vm_ssh_private_key_secret_name
  ssl_certificate_secret_name    = var.ssl_certificate_secret_name
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
}

module "remote_state" {
  source               = "./modules/storage_account"
  resource_group_name  = module.resource_group.resource_group_name
  location             = var.location
  storage_account_name = var.storage_account_name
  container_name       = "tfstate"
}

module "network" {
  source              = "./modules/network"
  location            = var.location
  resource_group_name = module.resource_group.resource_group_name
  vnet_name           = "main-vnet"
  vnet_address_space  = "10.0.0.0/16"
  subnets = [
    {
      name           = "db-subnet"
      address_prefix = "10.0.1.0/24"
    },
    {
      name           = "vm-subnet"
      address_prefix = "10.0.2.0/24"
    },
    {
      name           = "vmss-subnet"
      address_prefix = "10.0.3.0/24"
    },
  ]
  nsg_name           = "main-nsg"
  allowed_source_ips = var.allowed_source_ips
  domain_name        = var.domain_name
}

module "sql_server" {
  source                 = "./modules/sql_server"
  location               = "Poland Central"
  secondary_location     = "Germany West Central"
  resource_group_name    = module.resource_group.resource_group_name
  sql_server_name        = "pavsupr-sql-server"
  sql_database_name      = "pavsuprdb"
  sql_admin_username     = var.sql_admin_username
  sql_admin_password     = module.key_vault.sql_admin_password
  allowed_ip_range_start = var.allowed_ip_range_start
  allowed_ip_range_end   = var.allowed_ip_range_end
  vm_ip_to_allow         = module.network.vm_public_ip_address
  vmss_lb_ip_to_allow    = module.network.vmss_lb_public_ip_address
}

module "vm" {
  source                     = "./modules/vm"
  location                   = var.location
  resource_group_name        = module.resource_group.resource_group_name
  vm_name                    = "project-vm"
  vm_size                    = "Standard_B1s"
  subnet_id                  = module.network.subnet_ids["vm-subnet"]
  public_ip_address          = module.network.vm_public_ip_address
  public_ip_id               = module.network.vm_public_ip_id
  vm_admin_username          = var.vm_admin_username
  admin_ssh_public_key       = var.admin_ssh_public_key
  admin_ssh_private_key      = module.key_vault.vm_ssh_private_key
  sql_connection_string      = module.sql_server.jdbc_connection_string
  sql_server_host            = module.sql_server.sql_server_failover_group_name
  sql_database_name          = module.sql_server.sql_database_name
  sql_admin_username         = var.sql_admin_username
  sql_admin_password         = module.key_vault.sql_admin_password
  ssl_certificate_pfx_base64 = module.key_vault.ssl_certificate_pfx_base64
}

resource "null_resource" "wait_for_setup" {
  depends_on = [module.vm]

  triggers = {
    vm_id = module.vm.vm_id
  }

  connection {
    type        = "ssh"
    host        = module.network.vm_public_ip_address
    user        = var.vm_admin_username
    private_key = module.key_vault.vm_ssh_private_key
    timeout     = "1m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "sudo waagent -deprovision+user --force"
    ]
  }
}

resource "null_resource" "deallocate_vm" {
  depends_on = [null_resource.wait_for_setup]

  triggers = {
    vm_id = module.vm.vm_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOF
      $ErrorActionPreference = "Stop"
      
      $vmName = '${module.vm.vm_name}'
      $rgName = '${module.resource_group.resource_group_name}'

      Write-Host "Stopping VM $vmName..."
      az vm stop --name $vmName --resource-group $rgName
      
      Write-Host "Deallocating VM $vmName..."
      az vm deallocate --name $vmName --resource-group $rgName

      Write-Host "Verifying VM power state..."
      do {
        Start-Sleep -Seconds 5
        $power = az vm get-instance-view --name $vmName --resource-group $rgName `
          --query 'instanceView.statuses[?starts_with(code, `"PowerState/`")].code' --output tsv
        Write-Host "Current power state: $power"
      } while ($power -ne 'PowerState/deallocated')
      
      Write-Host "VM $vmName successfully stopped and deallocated"
    EOF
  }
}

resource "null_resource" "generalize_vm" {
  depends_on = [null_resource.deallocate_vm]

  triggers = {
    vm_id = module.vm.vm_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOF
      $ErrorActionPreference = "Stop"
      
      $vmName = '${module.vm.vm_name}'
      $rgName = '${module.resource_group.resource_group_name}'
      
      # Double-check power state before generalizing
      $power = az vm get-instance-view --name $vmName --resource-group $rgName `
        --query 'instanceView.statuses[?starts_with(code, `"PowerState/`")].code' --output tsv
      Write-Host "Current VM power state: $power"
      
      if ($power -ne 'PowerState/deallocated') {
        throw "VM must be deallocated before generalization. Current state: $power"
      }
      
      Write-Host "Generalizing VM $vmName..."
      az vm generalize --name $vmName --resource-group $rgName
      
      if ($LASTEXITCODE -ne 0) {
        throw "Failed to generalize VM"
      }
      
      Write-Host "VM $vmName successfully generalized"
    EOF
  }
}

module "image_gallery" {
  depends_on = [null_resource.generalize_vm]

  source              = "./modules/image_gallery"
  resource_group_name = module.resource_group.resource_group_name
  location            = var.location
  vm_id               = module.vm.vm_id
}

module "vmss" {
  source                         = "./modules/vmss"
  resource_group_name            = module.resource_group.resource_group_name
  location                       = var.location
  subnet_id                      = module.network.subnet_ids["vmss-subnet"]
  vm_admin_username              = var.vm_admin_username
  admin_ssh_public_key           = var.admin_ssh_public_key
  shared_image_id                = module.image_gallery.shared_image_id
  vmss_lb_public_ip_address_id   = module.network.vmss_lb_public_ip_address_id
  frontend_ip_configuration_name = "PublicIPAddress"
}
