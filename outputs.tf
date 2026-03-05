output "shared_vpc_id" {
  description = "The ID of the Shared VPC in the Host Project"
  value       = google_compute_network.shared_vpc.id
}

output "shared_subnet_id" {
  description = "The ID of the Subnet shared to the Service Project"
  value       = google_compute_subnetwork.shared_subnet.id
}