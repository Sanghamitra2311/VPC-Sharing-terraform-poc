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

MIT
