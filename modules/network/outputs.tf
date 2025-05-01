output "subnet_ids" {
  value = { for i, j in azurerm_subnet.this : i => j.id }
}

output "vm_public_ip_address" {
  value = azurerm_public_ip.vm.ip_address
}

output "vm_public_ip_id" {
  value = azurerm_public_ip.vm.id
}

output "vmss_lb_public_ip_address" {
  value = azurerm_public_ip.vmss_lb.ip_address
}

output "vmss_lb_public_ip_address_id" {
  value = azurerm_public_ip.vmss_lb.id
}
