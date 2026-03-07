provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-hub-spoke-basic"
  location = "East US"
}

module "hub_spoke" {
  source = "../../"

  name_prefix            = "basic"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  hub_vnet_address_space = ["10.0.0.0/16"]

  spoke_vnets = {
    workload = {
      address_space = ["10.1.0.0/16"]
      subnets = {
        default = {
          address_prefixes = ["10.1.0.0/24"]
        }
      }
      route_through_firewall = true
    }
  }

  enable_firewall    = true
  enable_bastion     = true
  enable_vpn_gateway = false
  enable_expressroute = false
  enable_route_server = false

  tags = {
    Environment = "dev"
    Example     = "basic"
  }
}

output "hub_vnet_id" {
  value = module.hub_spoke.hub_vnet_id
}

output "firewall_private_ip" {
  value = module.hub_spoke.firewall_private_ip
}
