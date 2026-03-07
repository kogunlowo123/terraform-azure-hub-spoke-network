variable "name_prefix" {
  description = "Prefix to use for all resource names."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy resources into."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub virtual network."
  type        = list(string)
}

variable "hub_subnets" {
  description = "Map of additional hub subnets to create (excluding reserved subnets which are created automatically)."
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {}
}

variable "spoke_vnets" {
  description = "Map of spoke virtual networks to create and peer with the hub."
  type = map(object({
    address_space          = list(string)
    subnets = map(object({
      address_prefixes = list(string)
    }))
    route_through_firewall = bool
  }))
  default = {}
}

variable "enable_firewall" {
  description = "Whether to deploy Azure Firewall in the hub."
  type        = bool
  default     = true
}

variable "firewall_sku_tier" {
  description = "SKU tier for the Azure Firewall. Possible values: Standard, Premium."
  type        = string
  default     = "Premium"
}

variable "firewall_threat_intel_mode" {
  description = "Threat intelligence mode for the Azure Firewall. Possible values: Off, Alert, Deny."
  type        = string
  default     = "Deny"
}

variable "firewall_policy_rule_collection_groups" {
  description = "List of firewall policy rule collection groups to create."
  type = list(object({
    name     = string
    priority = number
    network_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name                  = string
        protocols             = list(string)
        source_addresses      = list(string)
        destination_addresses = list(string)
        destination_ports     = list(string)
      }))
    })), [])
    application_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name              = string
        source_addresses  = list(string)
        destination_fqdns = list(string)
        protocols = list(object({
          type = string
          port = number
        }))
      }))
    })), [])
    nat_rule_collections = optional(list(object({
      name     = string
      priority = number
      action   = string
      rules = list(object({
        name                = string
        protocols           = list(string)
        source_addresses    = list(string)
        destination_address = string
        destination_ports   = list(string)
        translated_address  = string
        translated_port     = number
      }))
    })), [])
  }))
  default = []
}

variable "enable_bastion" {
  description = "Whether to deploy Azure Bastion in the hub."
  type        = bool
  default     = true
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion. Possible values: Basic, Standard."
  type        = string
  default     = "Standard"
}

variable "enable_vpn_gateway" {
  description = "Whether to deploy a VPN Gateway in the hub."
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "SKU for the VPN Gateway."
  type        = string
  default     = "VpnGw1"
}

variable "vpn_gateway_type" {
  description = "Type of VPN Gateway. Possible values: Vpn, ExpressRoute."
  type        = string
  default     = "Vpn"
}

variable "enable_expressroute" {
  description = "Whether to deploy an ExpressRoute Gateway in the hub."
  type        = bool
  default     = false
}

variable "expressroute_sku" {
  description = "SKU for the ExpressRoute Gateway."
  type        = string
  default     = "Standard"
}

variable "enable_route_server" {
  description = "Whether to deploy Azure Route Server in the hub."
  type        = bool
  default     = false
}

variable "enable_dns_proxy" {
  description = "Whether to enable DNS proxy on the Azure Firewall policy."
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic settings."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
