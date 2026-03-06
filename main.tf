# ==========================================
# 1. ENABLE HOST PROJECT
# ==========================================
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project_id
}

# ==========================================
# 2. CREATE THE VPC
# ==========================================
resource "google_compute_network" "shared_vpc" {
  name                    = var.network_name
  project                 = var.host_project_id
  auto_create_subnetworks = false
  depends_on              = [google_compute_shared_vpc_host_project.host]
}

# ==========================================
# 3. CREATE MULTIPLE SUBNETS DYNAMICALLY
# ==========================================
resource "google_compute_subnetwork" "shared_subnet" {
  for_each = var.subnets

  name          = each.key
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.shared_vpc.id
  project       = var.host_project_id
}

# ==========================================
# 4 & 5. ATTACH MULTIPLE SERVICE PROJECTS 
# ==========================================
# This extracts a unique list of project IDs so Terraform doesn't crash 
# if two subnets share the same service project.
locals {
  unique_service_projects = toset([for k, v in var.subnets : v.service_project_id])
}

resource "google_compute_shared_vpc_service_project" "service_attach" {
  for_each        = local.unique_service_projects
  host_project    = var.host_project_id
  service_project = each.value
}

data "google_project" "service_projects" {
  for_each   = local.unique_service_projects
  project_id = each.value
}

# Present each subnet strictly to its mapped Service Project
resource "google_compute_subnetwork_iam_member" "subnet_user" {
  for_each = var.subnets

  project    = var.host_project_id
  region     = each.value.region
  subnetwork = google_compute_subnetwork.shared_subnet[each.key].name
  role       = "roles/compute.networkUser"

  # Dynamically fetches the correct project number based on the subnet's mapped project ID
  member = "serviceAccount:${data.google_project.service_projects[each.value.service_project_id].number}@cloudservices.gserviceaccount.com"
}

# ==========================================
# FIREWALL RULES (UNIFIED ENGINE)
# ==========================================
resource "google_compute_firewall" "unified_rules" {
  for_each = var.firewall_rules

  name      = "${var.network_name}-${each.key}"
  project   = var.host_project_id
  network   = google_compute_network.shared_vpc.name
  direction = each.value.direction
  priority  = each.value.priority

  target_tags             = length(each.value.target_tags) > 0 ? each.value.target_tags : null
  target_service_accounts = length(each.value.target_service_accounts) > 0 ? each.value.target_service_accounts : null

  source_ranges      = each.value.direction == "INGRESS" ? each.value.ranges : null
  destination_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null

  dynamic "allow" {
    for_each = each.value.action == "allow" ? each.value.rules : []
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.action == "deny" ? each.value.rules : []
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

resource "google_compute_firewall" "default_deny_all_ingress" {
  name          = "${var.network_name}-default-deny-all-ingress"
  project       = var.host_project_id
  network       = google_compute_network.shared_vpc.name
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  deny { protocol = "all" }
}

resource "google_compute_firewall" "default_deny_all_egress" {
  name               = "${var.network_name}-default-deny-all-egress"
  project            = var.host_project_id
  network            = google_compute_network.shared_vpc.name
  direction          = "EGRESS"
  priority           = 65534
  destination_ranges = ["0.0.0.0/0"]
  deny { protocol = "all" }
}

# ==========================================
# OPTIONAL: PRIVATE SERVICE ACCESS (PSA)
# ==========================================
# 1. Dynamically loop through the map ONLY if create_psa is true

resource "google_compute_global_address" "psa_range" {
  for_each      = var.create_psa ? var.psa_ranges : {}
  name         = "${var.network_name}-${each.key}"
  project      = var.host_project_id
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  # Uses the explicit IP if provided, otherwise tells GCP to auto-allocate
  address       = each.value.address != "" ? each.value.address : null
  prefix_length = each.value.prefix_length
  network       = google_compute_network.shared_vpc.id
}

# 2. Feed all of those allocations into a single VPC Peering connection
resource "google_service_networking_connection" "psa_connection" {
  # Only runs if create_psa is true AND there is at least 1 range in the map.
  count = var.create_psa && length(var.psa_ranges) > 0 ? 1 : 0

  network = google_compute_network.shared_vpc.id
  service = "servicenetworking.googleapis.com"

  # Dynamically collects the names of EVERY address generated in the block above
  reserved_peering_ranges = [for range in google_compute_global_address.psa_range : range.name]
}