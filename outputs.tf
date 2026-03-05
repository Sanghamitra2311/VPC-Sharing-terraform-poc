output "shared_vpc_id" {
  description = "The ID of the global Shared VPC"
  value       = google_compute_network.shared_vpc.id
}

output "presented_subnets" {
  description = "Map of all created subnets and their IDs"
  value       = { for k, v in google_compute_subnetwork.shared_subnet : k => v.id }
}

output "deployed_firewall_rules" {
  description = "List of all firewall rules successfully deployed"
  value = concat(
    [for rule in google_compute_firewall.unified_rules : rule.name],
    [
      google_compute_firewall.default_deny_all_ingress.name,
      google_compute_firewall.default_deny_all_egress.name
    ]
  )
}

output "psa_allocation_name" {
  description = "The name of the PSA IP allocation"
  value       = try(google_compute_global_address.psa_range[0].name, "PSA not created")
}