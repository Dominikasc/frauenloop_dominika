output "resource_group_name" {
  description = "The name of the created resource group."
  value       = azurerm_resource_group.fl_rg.name
}

output "virtual_network_name" {
  description = "The name of the created virtual network."
  value       = azurerm_virtual_network.vnet.name
}

output "frontend_subnet_name" {
  description = "The name of the frontend subnet."
  value       = azurerm_subnet.frontend.name
}

output "backend_subnet_name" {
  description = "The name of the backend subnet."
  value       = azurerm_subnet.backend.name
}

output "backend_private_ip" {
  value = azurerm_network_interface.vm_nic.private_ip_address
}

output "client_object_id" {
  value = data.azurerm_client_config.current.object_id
}