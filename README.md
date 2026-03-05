# GCP Shared VPC Terraform Module

This Terraform configuration provisions a secure, production-grade Shared VPC environment on Google Cloud Platform (GCP), including:

- Host and service project setup
- Custom VPC and subnet creation
- Shared VPC attachment
- Unified, map-driven firewall rules (ingress/egress, allow/deny, default deny-all)
- Optional Private Service Access (PSA) for Google-managed services

## Features

- **Shared VPC Host Project**: Enables VPC sharing for a central host project.
- **Custom VPC & Subnet**: Creates a VPC and a custom subnet in the specified region.
- **Service Project Attachment**: Attaches a service project to the host for resource sharing.
- **IAM Permissions**: Grants the service project network user access to the subnet.
- **Unified Firewall Engine**: Define all custom firewall rules in a single map variable (`firewall_rules`) for both ingress and egress, supporting allow/deny, priorities, targets, and protocol/port granularity.
- **Default Deny-All**: Secure by default—only explicitly allowed traffic is permitted.
- **Private Service Access (Optional)**: Allocates an internal IP range and connects to Google APIs/services privately.

## File Structure

- `main.tf` – Main infrastructure resources and unified firewall rules
- `variables.tf` – Input variables for customization
- `outputs.tf` – Useful outputs (VPC ID, subnet ID, firewall rules, PSA info)
- `terraform.tfvars` – Example variable values (edit for your environment)
- `providers.tf` – Provider configuration

## Usage

1. **Clone this repository** and navigate to the project directory.
2. **Edit `terraform.tfvars`** to set your project IDs, region, network/subnet names, and firewall rules as needed.
3. **Initialize Terraform**:
   ```sh
   terraform init
   ```
4. **Review the plan**:
   ```sh
   terraform plan
   ```
5. **Apply the configuration**:
   ```sh
   terraform apply
   ```

## Example `terraform.tfvars`

```hcl
host_project_id    = "your-host-project-id"
service_project_id = "your-service-project-id"
region             = "asia-southeast1"
network_name       = "shared-vpc-migration"
subnet_name        = "presented-subnet"
subnet_cidr        = "10.238.19.128/25"
create_psa         = false
psa_prefix_length  = 24

firewall_rules = {
	"allow-internal-subnet" = {
		direction = "INGRESS"
		action    = "allow"
		priority  = 1000
		ranges    = ["10.238.19.128/25"]
		rules = [
			{ protocol = "all", ports = [] }
		]
	}
}
```

## Firewall Rule Map Schema

Each entry in `firewall_rules` is a map with the following structure:

```hcl
firewall_rules = {
	"rule-name" = {
		direction = "INGRESS" # or "EGRESS"
		action    = "allow"   # or "deny"
		priority  = 1000       # Lower is higher priority
		ranges    = ["10.0.0.0/8"] # Source (INGRESS) or destination (EGRESS) ranges
		target_tags             = ["web"]         # (Optional)
		target_service_accounts = ["my-sa@project.iam.gserviceaccount.com"] # (Optional)
		rules = [
			{ protocol = "tcp", ports = ["22"] },
			{ protocol = "icmp", ports = [] }
		]
	}
}
```

## Outputs

- `shared_vpc_id`: The VPC network ID
- `presented_subnet_id`: The subnet ID
- `deployed_firewall_rules`: List of firewall rules created
- `psa_allocation_name`: Name of the PSA IP allocation (if created)

## Notes

- The default configuration is secure: all ingress/egress is denied except what you explicitly allow.
- You must have the necessary IAM permissions in both host and service projects.
- PSA is optional and only needed for private Google API access.

## License

MIT# Enterprise GCP Shared VPC & Firewall Module

This Terraform module provisions a production-grade, Hub-and-Spoke Shared VPC architecture in Google Cloud Platform (GCP). It is designed to be highly scalable, utilizing dynamic maps to deploy multiple subnets, attach various service projects, and manage complex firewall rules through a single, unified engine.



## 🏗️ Architecture & Features

This module handles the complete lifecycle of a Shared VPC foundation:

1. **Host Project Initialization**: Automatically enables the Shared VPC Host feature on the designated host project (`theta-signal-418711`).
2. **Global VPC Creation**: Deploys a custom mode VPC network.
3. **Dynamic Subnet Mapping**: Uses a `map(object)` to dynamically generate any number of subnets across different regions and CIDR ranges.
4. **Service Project Attachment & IAM Handshake**: 
   * Safely links multiple unique service projects (e.g., `ornate-node-483516-e3`) to the Host project.
   * Dynamically fetches the hidden Google API service account numbers.
   * Grants precise `roles/compute.networkUser` permissions *only* for the specific subnets assigned to that service project.
5. **Zero-Trust Firewall Engine**: 
   * Deploys hardcoded `Priority 65534` Default Deny-All rules for both Ingress and Egress to secure the network boundary.
   * Utilizes a DRY (Don't Repeat Yourself) `for_each` engine to dynamically generate explicit Allow/Deny, Ingress/Egress rules from a single variable map.
6. **Optional Private Service Access (PSA)**: Configures internal IP allocation and VPC peering to Google Managed Services (like Cloud SQL) with toggleable settings.

---

## 🚀 Usage Guide

You do not need to modify the `main.tf` file to scale this infrastructure. All infrastructure changes are driven entirely through the `terraform.tfvars` file.

### Example `terraform.tfvars`

```hcl
host_project_id = "theta-signal-418711"
network_name    = "shared-vpc-migration"

# ==========================================
# 1. SUBNET & SERVICE PROJECT ROUTING
# ==========================================
# Add as many subnets as needed. You can map multiple subnets 
# to the same service project safely.
subnets = {
  "presented-subnet-1" = {
    region             = "asia-southeast1"
    cidr               = "10.238.19.128/25"
    service_project_id = "ornate-node-483516-e3"
  },
  "database-subnet-2" = {
    region             = "asia-southeast1"
    cidr               = "10.238.19.0/26"
    service_project_id = "ornate-node-483516-e3"
  }
}

# ==========================================
# 2. UNIFIED FIREWALL RULES
# ==========================================
# Defines custom firewall rules that override the Default Deny-All.
firewall_rules = {
  "allow-internal-traffic" = {
    direction = "INGRESS"
    action    = "allow"
    priority  = 1000
    ranges    = ["10.238.19.0/24"] 
    rules     = [{ protocol = "all", ports = [] }]
  }
}

# ==========================================
# 3. PRIVATE SERVICE ACCESS (Optional)
# ==========================================
create_psa        = false
psa_address       = "10.240.0.0"  # Leave as "" for auto-allocation
psa_prefix_length = 24

```

## Screenshots
<img width="1080" height="659" alt="image" src="https://github.com/user-attachments/assets/1fb0372f-e43c-4e00-b443-86c161282eb7" />

