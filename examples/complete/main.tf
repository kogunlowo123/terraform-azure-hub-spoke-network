provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-hub-spoke-complete"
  location = "East US 2"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-hub-spoke-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

module "hub_spoke" {
  source = "../../"

  name_prefix            = "complete"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  hub_vnet_address_space = ["10.0.0.0/16"]

  hub_subnets = {
    SharedServices = {
      address_prefixes = ["10.0.10.0/24"]
    }
    DnsResolver = {
      address_prefixes = ["10.0.11.0/24"]
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
        integration = {
          address_prefixes = ["10.1.2.0/24"]
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
        analytics = {
          address_prefixes = ["10.2.2.0/24"]
        }
      }
      route_through_firewall = true
    }
    dmz = {
      address_space = ["10.3.0.0/16"]
      subnets = {
        public = {
          address_prefixes = ["10.3.0.0/24"]
        }
        private = {
          address_prefixes = ["10.3.1.0/24"]
        }
      }
      route_through_firewall = false
    }
  }

  enable_firewall            = true
  firewall_sku_tier          = "Premium"
  firewall_threat_intel_mode = "Deny"
  enable_bastion             = true
  bastion_sku                = "Standard"
  enable_vpn_gateway         = true
  vpn_gateway_sku            = "VpnGw2"
  vpn_gateway_type           = "Vpn"
  enable_expressroute        = true
  expressroute_sku           = "Standard"
  enable_route_server        = true
  enable_dns_proxy           = true

  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  firewall_policy_rule_collection_groups = [
    {
      name     = "platform-rcg"
      priority = 100
      network_rule_collections = [
        {
          name     = "allow-dns"
          priority = 100
          action   = "Allow"
          rules = [
            {
              name                  = "dns-to-azure"
              protocols             = ["UDP", "TCP"]
              source_addresses      = ["10.0.0.0/8"]
              destination_addresses = ["168.63.129.16"]
              destination_ports     = ["53"]
            }
          ]
        },
        {
          name     = "allow-ntp"
          priority = 200
          action   = "Allow"
          rules = [
            {
              name                  = "ntp"
              protocols             = ["UDP"]
              source_addresses      = ["10.0.0.0/8"]
              destination_addresses = ["*"]
              destination_ports     = ["123"]
            }
          ]
        }
      ]
      application_rule_collections = [
        {
          name     = "allow-azure-services"
          priority = 300
          action   = "Allow"
          rules = [
            {
              name              = "azure-management"
              source_addresses  = ["10.0.0.0/8"]
              destination_fqdns = ["*.management.azure.com", "*.azure.com", "*.microsoft.com"]
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
    },
    {
      name     = "app-rcg"
      priority = 200
      network_rule_collections = [
        {
          name     = "allow-app-to-data"
          priority = 100
          action   = "Allow"
          rules = [
            {
              name                  = "sql"
              protocols             = ["TCP"]
              source_addresses      = ["10.1.0.0/16"]
              destination_addresses = ["10.2.0.0/16"]
              destination_ports     = ["1433", "5432"]
            }
          ]
        }
      ]
      application_rule_collections = []
      nat_rule_collections         = []
    }
  ]

  tags = {
    Environment = "production"
    Example     = "complete"
    ManagedBy   = "Terraform"
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

output "expressroute_gateway_id" {
  value = module.hub_spoke.expressroute_gateway_id
}

output "route_server_id" {
  value = module.hub_spoke.route_server_id
}

output "bastion_dns_name" {
  value = module.hub_spoke.bastion_dns_name
}
