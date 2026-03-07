provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-hub-spoke-advanced"
  location = "West Europe"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-hub-spoke-advanced"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "hub_spoke" {
  source = "../../"

  name_prefix            = "advanced"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  hub_vnet_address_space = ["10.0.0.0/16"]

  hub_subnets = {
    SharedServices = {
      address_prefixes = ["10.0.10.0/24"]
    }
  }

  spoke_vnets = {
    app = {
      address_space = ["10.1.0.0/16"]
      subnets = {
        frontend = {
          address_prefixes = ["10.1.0.0/24"]
        }
        backend = {
          address_prefixes = ["10.1.1.0/24"]
        }
      }
      route_through_firewall = true
    }
    data = {
      address_space = ["10.2.0.0/16"]
      subnets = {
        database = {
          address_prefixes = ["10.2.0.0/24"]
        }
        storage = {
          address_prefixes = ["10.2.1.0/24"]
        }
      }
      route_through_firewall = true
    }
  }

  enable_firewall           = true
  firewall_sku_tier         = "Premium"
  firewall_threat_intel_mode = "Deny"
  enable_bastion            = true
  bastion_sku               = "Standard"
  enable_vpn_gateway        = true
  vpn_gateway_sku           = "VpnGw1"
  enable_dns_proxy          = true

  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  firewall_policy_rule_collection_groups = [
    {
      name     = "default-rcg"
      priority = 100
      network_rule_collections = [
        {
          name     = "allow-dns"
          priority = 100
          action   = "Allow"
          rules = [
            {
              name                  = "dns"
              protocols             = ["UDP"]
              source_addresses      = ["10.0.0.0/8"]
              destination_addresses = ["168.63.129.16"]
              destination_ports     = ["53"]
            }
          ]
        }
      ]
      application_rule_collections = [
        {
          name     = "allow-web"
          priority = 200
          action   = "Allow"
          rules = [
            {
              name              = "allow-https"
              source_addresses  = ["10.0.0.0/8"]
              destination_fqdns = ["*.microsoft.com", "*.azure.com"]
              protocols = [
                {
                  type = "Https"
                  port = 443
                }
              ]
            }
          ]
        }
      ]
      nat_rule_collections = []
    }
  ]

  tags = {
    Environment = "staging"
    Example     = "advanced"
  }
}

output "hub_vnet_id" {
  value = module.hub_spoke.hub_vnet_id
}

output "spoke_vnet_ids" {
  value = module.hub_spoke.spoke_vnet_ids
}

output "firewall_private_ip" {
  value = module.hub_spoke.firewall_private_ip
}

output "vpn_gateway_id" {
  value = module.hub_spoke.vpn_gateway_id
}
