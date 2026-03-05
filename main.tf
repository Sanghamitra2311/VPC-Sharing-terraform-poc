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
# 3. CREATE THE SUBNET 
# ==========================================
resource "google_compute_subnetwork" "shared_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.shared_vpc.id
  project       = var.host_project_id
}

# ==========================================
# 4 & 5. ATTACH SERVICE PROJECT & PRESENT SUBNET
# (This was missing from your code)
# ==========================================
resource "google_compute_shared_vpc_service_project" "service_attach" {
  host_project    = var.host_project_id
  service_project = var.service_project_id
}

data "google_project" "service_project" {
  project_id = var.service_project_id
}

resource "google_compute_subnetwork_iam_member" "subnet_user" {
  project    = var.host_project_id
  region     = google_compute_subnetwork.shared_subnet.region
  subnetwork = google_compute_subnetwork.shared_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}

# ==========================================
# FIREWALL RULES
# ==========================================

# Enhanced ALLOW Firewall (Ingress)
resource "google_compute_firewall" "dynamic_allow_ingress" {
  count                   = length(var.allow_rules) > 0 ? 1 : 0
  name                    = "${var.network_name}-allow-ingress"
  project                 = var.host_project_id
  network                 = google_compute_network.shared_vpc.name
  direction               = "INGRESS"
  priority                = 1000
  target_tags             = length(var.firewall_target_tags) > 0 ? var.firewall_target_tags : null
  target_service_accounts = length(var.firewall_target_service_accounts) > 0 ? var.firewall_target_service_accounts : null
  source_ranges           = var.allow_source_ranges

  dynamic "allow" {
    for_each = var.allow_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# Enhanced ALLOW Firewall (Egress)
resource "google_compute_firewall" "dynamic_allow_egress" {
  count                   = length(var.allow_egress_rules) > 0 ? 1 : 0
  name                    = "${var.network_name}-allow-egress"
  project                 = var.host_project_id
  network                 = google_compute_network.shared_vpc.name
  direction               = "EGRESS"
  priority                = 1000
  target_tags             = length(var.firewall_target_tags) > 0 ? var.firewall_target_tags : null
  target_service_accounts = length(var.firewall_target_service_accounts) > 0 ? var.firewall_target_service_accounts : null
  destination_ranges      = var.allow_egress_destination_ranges

  dynamic "allow" {
    for_each = var.allow_egress_rules
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}

# Default Deny-All Ingress
resource "google_compute_firewall" "default_deny_all_ingress" {
  name          = "${var.network_name}-default-deny-all-ingress"
  project       = var.host_project_id
  network       = google_compute_network.shared_vpc.name
  direction     = "INGRESS"
  priority      = 65534 # FIXED: Lowest priority catch-all
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

# Default Deny-All Egress
resource "google_compute_firewall" "default_deny_all_egress" {
  name               = "${var.network_name}-default-deny-all-egress"
  project            = var.host_project_id
  network            = google_compute_network.shared_vpc.name
  direction          = "EGRESS"
  priority           = 65534 # FIXED: Lowest priority catch-all
  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

# ==========================================
# 6. OPTIONAL: PRIVATE SERVICE ACCESS (PSA)
# ==========================================
resource "google_compute_global_address" "psa_range" {
  count         = var.create_psa ? 1 : 0
  name          = "${var.network_name}-psa-allocation"
  project       = var.host_project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_prefix_length
  network       = google_compute_network.shared_vpc.id
}

resource "google_service_networking_connection" "psa_connection" {
  count                   = var.create_psa ? 1 : 0
  network                 = google_compute_network.shared_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range[0].name]
}