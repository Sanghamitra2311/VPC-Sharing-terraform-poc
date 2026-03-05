# ==========================================
# HOST PROJECT RESOURCES (Theta)
# ==========================================

# Enable Shared VPC in Host Project
resource "google_compute_shared_vpc_host_project" "host" {

  project = var.host_project_id
}

# Create the VPC Network in Host Project
resource "google_compute_network" "shared_vpc" {

  name                    = var.network_name
  project                 = var.host_project_id
  auto_create_subnetworks = false
  depends_on              = [google_compute_shared_vpc_host_project.host]
}

# Create the Subnet to be shared
resource "google_compute_subnetwork" "shared_subnet" {

  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.subnet_region
  network       = google_compute_network.shared_vpc.id
  project       = var.host_project_id
}

# Host Firewall: Allow SSH to the Shared VPC
resource "google_compute_firewall" "allow_ssh" {

  name    = "allow-ssh-shared-network"
  network = google_compute_network.shared_vpc.name
  project = var.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# ==========================================
# SHARED VPC ATTACHMENT & IAM (Managed via Host)
# ==========================================

#  Attach the Service Project to the Host
resource "google_compute_shared_vpc_service_project" "service_attach" {

  host_project    = var.host_project_id
  service_project = var.service_project_id
}

# Fetch Service Project Data (To get the Project Number dynamically)
data "google_project" "service_project" {

  project_id = var.service_project_id
}

# By assigning this to the HOST PROJECT rather than a specific subnet, 
# the Service Project gets access to ALL subnets in the Shared VPC.
resource "google_project_iam_member" "project_network_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}


