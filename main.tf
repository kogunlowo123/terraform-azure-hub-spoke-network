###############################################################################
# Hub Virtual Network
###############################################################################

resource "azurerm_virtual_network" "hub" {
  name                = "${var.name_prefix}-hub-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each = local.hub_subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
}

###############################################################################
# Spoke Virtual Networks
###############################################################################

resource "azurerm_virtual_network" "spoke" {
  for_each = var.spoke_vnets

  name                = "${var.name_prefix}-${each.key}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = each.value.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "spoke" {
  for_each = {
    for s in local.spoke_subnets : "${s.vnet_key}-${s.subnet_key}" => s
  }

  name                 = each.value.subnet_key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke[each.value.vnet_key].name
  address_prefixes     = each.value.address_prefixes
}

###############################################################################
# VNet Peering: Hub <-> Spoke
###############################################################################

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_vnets

  name                         = "${var.name_prefix}-hub-to-${each.key}"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.enable_vpn_gateway || var.enable_expressroute
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spoke_vnets

  name                         = "${var.name_prefix}-${each.key}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = var.enable_vpn_gateway || var.enable_expressroute

  depends_on = [
    azurerm_virtual_network_gateway.vpn,
    azurerm_virtual_network_gateway.expressroute,
  ]
}

###############################################################################
# Azure Firewall
###############################################################################

resource "azurerm_public_ip" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                = "${var.name_prefix}-fw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  count = var.enable_firewall ? 1 : 0

  name                     = "${var.name_prefix}-fw-policy"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = var.firewall_threat_intel_mode
  tags                     = var.tags

  dns {
    proxy_enabled = var.enable_dns_proxy
  }

  dynamic "intrusion_detection" {
    for_each = var.firewall_sku_tier == "Premium" ? [1] : []
    content {
      mode = "Alert"
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  for_each = {
    for rcg in var.firewall_policy_rule_collection_groups : rcg.name => rcg
  }

  name               = each.value.name
  firewall_policy_id = azurerm_firewall_policy.this[0].id
  priority           = each.value.priority

  dynamic "network_rule_collection" {
    for_each = each.value.network_rule_collections
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = each.value.application_rule_collections
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = rule.value.name
          source_addresses  = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              type = protocols.value.type
              port = protocols.value.port
            }
          }
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = each.value.nat_rule_collections
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

resource "azurerm_firewall" "this" {
  count = var.enable_firewall ? 1 : 0

  name                = "${var.name_prefix}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this[0].id
  threat_intel_mode   = var.firewall_threat_intel_mode
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

###############################################################################
# Azure Bastion
###############################################################################

resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name_prefix}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.bastion_sku
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.hub["AzureBastionSubnet"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

###############################################################################
# VPN Gateway
###############################################################################

resource "azurerm_public_ip" "vpn_gateway" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "${var.name_prefix}-vpngw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0

  name                = "${var.name_prefix}-vpngw"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.vpn_gateway_type
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vpngw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub["GatewaySubnet"].id
  }
}

###############################################################################
# ExpressRoute Gateway
###############################################################################

resource "azurerm_public_ip" "expressroute" {
  count = var.enable_expressroute ? 1 : 0

  name                = "${var.name_prefix}-ergw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "expressroute" {
  count = var.enable_expressroute ? 1 : 0

  name                = "${var.name_prefix}-ergw"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "ExpressRoute"
  sku                 = var.expressroute_sku
  tags                = var.tags

  ip_configuration {
    name                          = "ergw-ipconfig"
    public_ip_address_id          = azurerm_public_ip.expressroute[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub["GatewaySubnet"].id
  }
}

###############################################################################
# Azure Route Server
###############################################################################

resource "azurerm_public_ip" "route_server" {
  count = var.enable_route_server ? 1 : 0

  name                = "${var.name_prefix}-routeserver-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_route_server" "this" {
  count = var.enable_route_server ? 1 : 0

  name                             = "${var.name_prefix}-routeserver"
  resource_group_name              = var.resource_group_name
  location                         = var.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.route_server[0].id
  subnet_id                        = azurerm_subnet.hub["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags
}

###############################################################################
# Route Tables & UDRs (for spokes routing through the firewall)
###############################################################################

resource "azurerm_route_table" "spoke" {
  for_each = local.firewall_routed_spokes

  name                          = "${var.name_prefix}-${each.key}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = true
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.firewall_private_ip
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = {
    for s in local.spoke_subnets : "${s.vnet_key}-${s.subnet_key}" => s
    if lookup(local.firewall_routed_spokes, s.vnet_key, null) != null
  }

  subnet_id      = azurerm_subnet.spoke["${each.value.vnet_key}-${each.value.subnet_key}"].id
  route_table_id = azurerm_route_table.spoke[each.value.vnet_key].id
}

###############################################################################
# Diagnostic Settings
###############################################################################

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.enable_firewall && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-fw-diag"
  target_resource_id         = azurerm_firewall.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count = var.enable_bastion && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name_prefix}-bastion-diag"
  target_resource_id         = azurerm_bastion_host.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "BastionAuditLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
