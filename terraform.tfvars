host_project_id    = "theta-signal-418711"
service_project_id = "ornate-node-483516-e3"
region             = "asia-southeast1"

network_name = "shared-vpc-migration"
subnet_name  = "presented-subnet"
subnet_cidr  = "10.238.19.128/25"

# PSA Toggle
create_psa        = false
psa_prefix_length = 24

# -------------------------------------------
# BASELINE FIREWALL RULES
# -------------------------------------------

# 1. ALLOW INTERNAL SUBNET TRAFFIC (Ingress)
allow_rules = [
  {
    protocol = "all"
    ports    = []
  }
]
allow_source_ranges = ["10.238.19.128/25"] # Restricts source to the subnet CIDR

# 2. BLOCK ALL OUTBOUND (Egress)
# (Handled automatically by the 'default_deny_all_egress' block in main.tf)

# The other variables (deny_rules, allow_egress_rules) are safely 
# ignored because they default to empty lists [] in your variables.tf