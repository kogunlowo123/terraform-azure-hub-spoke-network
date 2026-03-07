locals {
  # Reserved subnet definitions for the hub virtual network
  reserved_subnets = merge(
    var.enable_firewall ? {
      AzureFirewallSubnet = {
        address_prefixes = [cidrsubnet(var.hub_vnet_address_space[0], 2, 0)]
      }
    } : {},
    {
      GatewaySubnet = {
        address_prefixes = [cidrsubnet(var.hub_vnet_address_space[0], 2, 1)]
      }
    },
    var.enable_bastion ? {
      AzureBastionSubnet = {
        address_prefixes = [cidrsubnet(var.hub_vnet_address_space[0], 2, 2)]
      }
    } : {},
    var.enable_route_server ? {
      RouteServerSubnet = {
        address_prefixes = [cidrsubnet(var.hub_vnet_address_space[0], 2, 3)]
      }
    } : {}
  )

  # Merge reserved subnets with user-defined hub subnets
  hub_subnets = merge(local.reserved_subnets, var.hub_subnets)

  # Flatten spoke subnets for iteration
  spoke_subnets = flatten([
    for vnet_key, vnet in var.spoke_vnets : [
      for subnet_key, subnet in vnet.subnets : {
        vnet_key         = vnet_key
        subnet_key       = subnet_key
        address_prefixes = subnet.address_prefixes
      }
    ]
  ])

  # Spokes that require routing through the firewall
  firewall_routed_spokes = {
    for k, v in var.spoke_vnets : k => v if v.route_through_firewall && var.enable_firewall
  }

  # Firewall private IP address (used for UDR next hop)
  firewall_private_ip = var.enable_firewall ? azurerm_firewall.this[0].ip_configuration[0].private_ip_address : null
}
