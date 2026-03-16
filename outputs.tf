output "hub_vnet_id" {
  description = "The ID of the hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "The name of the hub virtual network."
  value       = azurerm_virtual_network.hub.name
}

output "hub_subnet_ids" {
  description = "Map of hub subnet names to their IDs."
  value       = { for k, v in azurerm_subnet.hub : k => v.id }
}

output "spoke_vnet_ids" {
  description = "Map of spoke VNet keys to their IDs."
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "spoke_vnet_names" {
  description = "Map of spoke VNet keys to their names."
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.name }
}

output "spoke_subnet_ids" {
  description = "Map of spoke subnet keys to their IDs."
  value       = { for k, v in azurerm_subnet.spoke : k => v.id }
}

output "firewall_id" {
  description = "The ID of the Azure Firewall."
  value       = var.enable_firewall ? azurerm_firewall.this[0].id : null
}

output "firewall_private_ip" {
  description = "The private IP address of the Azure Firewall."
  value       = var.enable_firewall ? azurerm_firewall.this[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall."
  value       = var.enable_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "firewall_policy_id" {
  description = "The ID of the Azure Firewall Policy."
  value       = var.enable_firewall ? azurerm_firewall_policy.this[0].id : null
}

output "bastion_id" {
  description = "The ID of the Azure Bastion Host."
  value       = var.enable_bastion ? azurerm_bastion_host.this[0].id : null
}

output "bastion_dns_name" {
  description = "The DNS name of the Azure Bastion Host."
  value       = var.enable_bastion ? azurerm_bastion_host.this[0].dns_name : null
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway."
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "vpn_gateway_public_ip" {
  description = "The public IP address of the VPN Gateway."
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}

output "expressroute_gateway_id" {
  description = "The ID of the ExpressRoute Gateway."
  value       = var.enable_expressroute ? azurerm_virtual_network_gateway.expressroute[0].id : null
}

output "route_server_id" {
  description = "The ID of the Azure Route Server."
  value       = var.enable_route_server ? azurerm_route_server.this[0].id : null
}

output "spoke_route_table_ids" {
  description = "Map of spoke VNet keys to their route table IDs."
  value       = { for k, v in azurerm_route_table.spoke : k => v.id }
}
