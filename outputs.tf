output "shared_vpc_id" {
  description = "The ID of the global Shared VPC"
  value       = google_compute_network.shared_vpc.id
}

output "presented_subnet_id" {
  description = "The Subnet shared with the Service Project"
  value       = google_compute_subnetwork.shared_subnet.id
}

output "deployed_firewall_rules" {
  description = "List of the names of all firewall rules successfully deployed"
  value = compact([
    try(google_compute_firewall.dynamic_allow_ingress[0].name, ""),
    try(google_compute_firewall.dynamic_allow_egress[0].name, ""),
    try(google_compute_firewall.dynamic_deny_ingress[0].name, ""),
    try(google_compute_firewall.dynamic_deny_egress[0].name, ""),
    google_compute_firewall.default_deny_all_ingress.name,
    google_compute_firewall.default_deny_all_egress.name
  ])
}

output "psa_allocation_name" {
  description = "The name of the PSA IP allocation"
  value       = try(google_compute_global_address.psa_range[0].name, "PSA not created")
}