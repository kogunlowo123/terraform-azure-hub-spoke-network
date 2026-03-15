# Industry Adaptation Guide

## Overview
The `terraform-azure-hub-spoke-network` module deploys a hub-and-spoke network topology on Azure with Azure Firewall (Standard/Premium), Bastion, VPN Gateway, ExpressRoute Gateway, Route Server, VNet peering, spoke route tables, firewall policy rule collection groups, diagnostic settings, and DNS proxy. This architecture provides centralized security and connectivity control for any regulated environment.

## Healthcare
### Compliance Requirements
- HIPAA, HITRUST, HL7 FHIR
### Configuration Changes
- Set `enable_firewall = true` with `firewall_sku_tier = "Premium"` to enable TLS inspection and IDPS for traffic carrying PHI.
- Set `firewall_threat_intel_mode = "Deny"` to block known malicious IPs and domains.
- Configure `firewall_policy_rule_collection_groups` with application rules restricting outbound traffic to approved healthcare endpoints (e.g., FHIR servers, EHR integrations).
- Set `enable_bastion = true` with `bastion_sku = "Standard"` for audited, just-in-time access to VMs without public IPs.
- Set `enable_vpn_gateway = true` for encrypted site-to-site connectivity to hospital data centers.
- Deploy PHI workloads in spoke VNets with `route_through_firewall = true` to force all traffic through centralized inspection.
- Set `log_analytics_workspace_id` for diagnostic settings on firewall and bastion (HIPAA audit requirements).
- Set `enable_dns_proxy = true` to centralize DNS resolution and prevent DNS exfiltration.
### Example Use Case
A health system deploys a hub-spoke network with Premium firewall inspecting all traffic between clinical application spokes, a VPN gateway connecting to three hospital campuses, and Bastion providing audited SSH/RDP access to management VMs.

## Finance
### Compliance Requirements
- SOX, PCI-DSS, SOC 2
### Configuration Changes
- Set `enable_firewall = true` with `firewall_sku_tier = "Premium"` for IDPS and TLS inspection of financial transaction traffic (PCI-DSS Requirement 1).
- Set `firewall_threat_intel_mode = "Deny"` for proactive threat blocking.
- Configure `firewall_policy_rule_collection_groups` with:
  - Network rules restricting CDE spoke traffic to specific ports and destinations.
  - Application rules allowing HTTPS only to payment processor endpoints.
  - NAT rules for controlled inbound access to trading platforms.
- Deploy PCI-scoped workloads in a dedicated spoke with `route_through_firewall = true`.
- Set `enable_expressroute = true` for private, high-bandwidth connectivity to trading venues and data centers.
- Set `enable_bastion = true` for audited administrative access (PCI-DSS Requirement 8).
- Enable diagnostics via `log_analytics_workspace_id` for firewall log retention (SOX audit trail).
### Example Use Case
A bank deploys its PCI CDE in an isolated spoke VNet, routes all traffic through Premium firewall with IDPS, connects to its primary data center via ExpressRoute, and uses Bastion for SOX-audited administrative access.

## Government
### Compliance Requirements
- FedRAMP, CMMC, NIST 800-53
### Configuration Changes
- Deploy in Azure Government regions.
- Set `enable_firewall = true` with `firewall_sku_tier = "Premium"` for IDPS (NIST SI-4) and TLS inspection.
- Set `firewall_threat_intel_mode = "Deny"` (NIST SI-3).
- Configure `firewall_policy_rule_collection_groups` implementing NIST SC-7 boundary protection rules.
- Set `enable_vpn_gateway = true` with `vpn_gateway_type = "Vpn"` for encrypted site-to-site connectivity (NIST SC-8).
- Set `enable_bastion = true` with `bastion_sku = "Standard"` for controlled remote access (NIST AC-17).
- Deploy workloads in spokes with `route_through_firewall = true` for centralized traffic inspection.
- Set `enable_route_server = true` for dynamic routing with network virtual appliances.
- Enable all diagnostic settings via `log_analytics_workspace_id` for continuous monitoring.
### Example Use Case
A defense contractor deploys a hub-spoke network in Azure Government with Premium firewall implementing NIST SC-7 boundary rules, VPN gateway connecting to SIPR-adjacent networks, and Route Server for dynamic routing with third-party NVAs.

## Retail / E-Commerce
### Compliance Requirements
- PCI-DSS, CCPA/GDPR
### Configuration Changes
- Set `enable_firewall = true` with `firewall_sku_tier = "Standard"` for cost-effective traffic inspection.
- Configure `spoke_vnets` with separate spokes for web tier, application tier, and data tier.
- Set `route_through_firewall = true` for data tier spokes to inspect all database traffic.
- Configure `firewall_policy_rule_collection_groups` with NAT rules for inbound web traffic and network rules restricting database access.
- Set `enable_bastion = true` for secure administrative access without public IPs.
- Deploy payment processing in an isolated spoke with Premium firewall tier for IDPS.
- Set `log_analytics_workspace_id` for PCI-DSS network monitoring requirements.
### Example Use Case
A retailer creates four spoke VNets (web, app, payments, data), routes payment spoke traffic through Premium firewall with IDPS, uses Standard firewall for web and app spokes, and deploys Bastion for developer access to staging environments.

## Education
### Compliance Requirements
- FERPA, COPPA
### Configuration Changes
- Set `enable_firewall = true` with `firewall_sku_tier = "Standard"` to filter outbound traffic from student-facing applications.
- Configure `firewall_policy_rule_collection_groups` with application rules enforcing web content filtering for COPPA compliance.
- Deploy student data workloads in a dedicated spoke with `route_through_firewall = true`.
- Set `enable_vpn_gateway = true` for campus network connectivity.
- Set `enable_bastion = true` for secure administrative access by campus IT.
- Set `enable_dns_proxy = true` for centralized DNS resolution across campus spokes.
### Example Use Case
A university deploys separate spokes for student services, research computing, and administrative systems, routes student-facing traffic through the firewall with web content filtering, and connects to campus networks via VPN gateway.

## SaaS / Multi-Tenant
### Compliance Requirements
- SOC 2, ISO 27001
### Configuration Changes
- Configure `spoke_vnets` with per-tenant or per-tier spokes for network-level isolation.
- Set `enable_firewall = true` with `firewall_sku_tier = "Premium"` for tenant traffic inspection and IDPS.
- Configure `firewall_policy_rule_collection_groups` with per-spoke rules controlling inter-tenant communication (default deny).
- Set `route_through_firewall = true` on all tenant spokes.
- Set `enable_expressroute = true` for enterprise tenants requiring private connectivity.
- Set `enable_vpn_gateway = true` for tenant site-to-site VPN requirements.
- Enable all diagnostic settings for SOC 2 audit evidence.
- Use `hub_subnets` for shared services (DNS, monitoring, identity) accessible from all spokes.
### Example Use Case
A SaaS provider creates individual spoke VNets per enterprise tenant, routes all inter-spoke traffic through Premium firewall with deny-all-except-allowed rules, offers ExpressRoute connectivity to premium tenants, and centralizes shared services in the hub.

## Cross-Industry Best Practices
- Use environment-based configuration by parameterizing `name_prefix`, `location`, and `tags` per environment.
- Always enable encryption in transit by deploying Azure Firewall with TLS inspection (Premium tier) and VPN/ExpressRoute for hybrid connectivity.
- Enable audit logging and monitoring by setting `log_analytics_workspace_id` for firewall and bastion diagnostic settings.
- Enforce least-privilege access controls by using Bastion for administrative access and firewall rules implementing default-deny policies.
- Implement network segmentation using the hub-spoke architecture with `route_through_firewall = true` for traffic inspection.
- Configure backup and disaster recovery by designing the hub-spoke topology across paired regions with redundant VPN/ExpressRoute gateways.
