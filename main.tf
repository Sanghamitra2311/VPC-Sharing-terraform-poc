# ==========================================
#       ENABLE HOST PROJECT
# ==========================================
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project_id
}

# ==========================================
#         CREATE THE VPC
# ==========================================
resource "google_compute_network" "shared_vpc" {
  name                    = var.network_name
  project                 = var.host_project_id
  auto_create_subnetworks = false
  depends_on              = [google_compute_shared_vpc_host_project.host]
}

# ==========================================
#         CREATE THE SUBNET 
# ==========================================
resource "google_compute_subnetwork" "shared_subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.shared_vpc.id
  project       = var.host_project_id
}

# ==========================================
#    ATTACH SERVICE PROJECT & PRESENT SUBNET

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
#         FIREWALL RULES
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

  # Smartly assigns ranges based on direction
  source_ranges      = each.value.direction == "INGRESS" ? each.value.ranges : null
  destination_ranges = each.value.direction == "EGRESS" ? each.value.ranges : null

  # Only builds an 'allow' block if the action is allow
  dynamic "allow" {
    for_each = each.value.action == "allow" ? each.value.rules : []
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  # Only builds a 'deny' block if the action is deny
  dynamic "deny" {
    for_each = each.value.action == "deny" ? each.value.rules : []
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

# Default Deny-All Ingress
resource "google_compute_firewall" "default_deny_all_ingress" {
  name          = "${var.network_name}-default-deny-all-ingress"
  project       = var.host_project_id
  network       = google_compute_network.shared_vpc.name
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  deny { protocol = "all" }
}

# Default Deny-All Egress
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
#   OPTIONAL: PRIVATE SERVICE ACCESS (PSA)
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
