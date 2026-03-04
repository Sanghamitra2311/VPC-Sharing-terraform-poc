terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Provider for the Host Project (Theta)
provider "google" {
  alias   = "host"
  project = var.host_project_id
  region  = var.subnet_region
}

# Provider for the Service Project (Ornate)
provider "google" {
  alias   = "service"
  project = var.service_project_id
  region  = var.subnet_region
}