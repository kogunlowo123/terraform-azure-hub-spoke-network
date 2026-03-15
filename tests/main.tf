resource "azurerm_resource_group" "test" {
  name     = "rg-hubspoke-test"
  location = "eastus2"
}

module "test" {
  source = "../"

  name_prefix         = "test"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location

  hub_vnet_address_space = ["10.0.0.0/16"]

  hub_subnets = {
    shared-services = {
      address_prefixes = ["10.0.4.0/24"]
    }
  }

  spoke_vnets = {
    workload = {
      address_space = ["10.1.0.0/16"]
      subnets = {
        app = {
          address_prefixes = ["10.1.0.0/24"]
        }
        data = {
          address_prefixes = ["10.1.1.0/24"]
        }
      }
      route_through_firewall = true
    }
  }

  enable_firewall            = true
  firewall_sku_tier          = "Premium"
  firewall_threat_intel_mode = "Deny"
  enable_bastion             = true
  bastion_sku                = "Standard"
  enable_vpn_gateway         = false
  enable_expressroute        = false
  enable_dns_proxy           = true

  tags = {
    Environment = "test"
    ManagedBy   = "terraform"
  }
}
