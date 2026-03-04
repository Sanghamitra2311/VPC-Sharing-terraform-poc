# ========================== HOST PROJECT RESOURCES (Theta) ======================

# 1. Enable Shared VPC in Host Project
resource "google_compute_shared_vpc_host_project" "host" {
  provider = google.host
  project  = var.host_project_id
}

# 2. Create the VPC Network in Host Project
resource "google_compute_network" "shared_vpc" {
  provider                = google.host
  name                    = var.network_name
  project                 = var.host_project_id
  auto_create_subnetworks = false
  depends_on              = [google_compute_shared_vpc_host_project.host]
}

# 3. Create the Subnet to be shared
resource "google_compute_subnetwork" "shared_subnet" {
  provider      = google.host
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.subnet_region
  network       = google_compute_network.shared_vpc.id
  project       = var.host_project_id
}

# 4. Host Firewall: Allow SSH to the Shared VPC
resource "google_compute_firewall" "allow_ssh" {
  provider = google.host
  name     = "allow-ssh-shared-network"
  network  = google_compute_network.shared_vpc.name
  project  = var.host_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# ====================SHARED VPC ATTACHMENT & IAM (Managed via Host)==================

# 5. Attach the Service Project to the Host
resource "google_compute_shared_vpc_service_project" "service_attach" {
  provider        = google.host
  host_project    = var.host_project_id
  service_project = var.service_project_id
}

# 6. Fetch Service Project Data (To get the Project Number dynamically)
data "google_project" "service_project" {
  provider   = google.service
  project_id = var.service_project_id
}

# 7. IAM: Grant Service Project's Cloud Services account access to the Subnet
# This is the automated permission that allows the Ornate project to consume the Theta subnet.
resource "google_compute_subnetwork_iam_member" "subnet_user" {
  provider   = google.host
  project    = var.host_project_id
  region     = google_compute_subnetwork.shared_subnet.region
  subnetwork = google_compute_subnetwork.shared_subnet.name
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${data.google_project.service_project.number}@cloudservices.gserviceaccount.com"
}

# ==========================================
# SERVICE PROJECT RESOURCES (Ornate)
# ==========================================

# 8. Create the Test VM in the Service Project
resource "google_compute_instance" "test_vm" {
  provider     = google.service
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = "${var.subnet_region}-a"
  project      = var.service_project_id

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    # CRITICAL: These two lines point back to the Host project's network
    subnetwork         = google_compute_subnetwork.shared_subnet.id
    subnetwork_project = var.host_project_id 
    
    access_config {} # Assigns an ephemeral public IP for testing
  }

  # Ensure the network sharing is fully set up before attempting to build the VM
  depends_on = [
    google_compute_shared_vpc_service_project.service_attach,
    google_compute_subnetwork_iam_member.subnet_user
  ]
}
#


