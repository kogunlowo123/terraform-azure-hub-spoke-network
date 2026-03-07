# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-03-07

### Added

- Hub virtual network with reserved subnets (AzureFirewallSubnet, GatewaySubnet, AzureBastionSubnet, RouteServerSubnet).
- Spoke virtual networks with configurable subnets and hub peering.
- Azure Firewall (Standard/Premium) with firewall policy, IDPS, DNS proxy, and rule collection groups.
- Azure Bastion (Basic/Standard) for secure VM access.
- VPN Gateway for site-to-site and point-to-site connectivity.
- ExpressRoute Gateway for private on-premises connectivity.
- Azure Route Server for dynamic route exchange.
- User-Defined Routes (UDRs) for spoke subnets routing through Azure Firewall.
- Diagnostic settings with Log Analytics workspace integration.
- Basic, advanced, and complete deployment examples.
