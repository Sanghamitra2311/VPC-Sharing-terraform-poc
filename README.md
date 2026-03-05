
# GCP Shared VPC Terraform Module

This Terraform configuration provisions a secure, production-grade Shared VPC environment on Google Cloud Platform (GCP), including:
- Host and service project setup
- Custom VPC and subnet creation
- Shared VPC attachment
- Fine-grained firewall rules (ingress/egress, allow/deny, default deny-all)
- Optional Private Service Access (PSA) for Google-managed services

## Features
- **Shared VPC Host Project**: Enables VPC sharing for a central host project.
- **Custom VPC & Subnet**: Creates a VPC and a custom subnet in the specified region.
- **Service Project Attachment**: Attaches a service project to the host for resource sharing.
- **IAM Permissions**: Grants the service project network user access to the subnet.
- **Advanced Firewall Rules**: Supports dynamic allow/deny rules for both ingress and egress, with default deny-all for maximum security.
- **Private Service Access (Optional)**: Allocates an internal IP range and connects to Google APIs/services privately.

## File Structure
- `main.tf` – Main infrastructure resources and firewall rules
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

allow_rules = [
  {
	 protocol = "all"
	 ports    = []
  }
]
allow_source_ranges = ["10.238.19.128/25"]
```

## Firewall Rule Variables
- `allow_rules`, `deny_rules`: Ingress allow/deny rules (protocol/ports)
- `allow_egress_rules`, `deny_egress_rules`: Egress allow/deny rules
- `firewall_target_tags`, `firewall_target_service_accounts`: Restrict rules to specific targets
- `allow_source_ranges`, `deny_source_ranges`: Source IPs for ingress
- `allow_egress_destination_ranges`, `deny_egress_destination_ranges`: Destination IPs for egress

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
MIT


