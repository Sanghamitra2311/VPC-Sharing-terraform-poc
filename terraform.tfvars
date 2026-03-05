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
firewall_rules = {

  "allow-internal-subnet" = {
    direction = "INGRESS"
    action    = "allow"
    priority  = 1000
    ranges    = ["10.238.19.128/25"] # Restricts source strictly to the subnet CIDR
    rules = [
      { protocol = "all", ports = [] }
    ]
  }

}