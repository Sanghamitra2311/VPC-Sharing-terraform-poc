host_project_id = "theta-signal-418711"
network_name    = "shared-vpc-migration"



# ==========================================
#     PRIVATE SERVICE ACCESS (PSA) MAP
# ==========================================
# We can define multiple ranges here. 

create_psa = false # Set to false to disable PSA entirely, even if ranges are defined below.
psa_ranges = {
  "sample-range-1" = {
    address       = "10.240.0.0" # Explicitly defined starting IP
    prefix_length = 24
  },

  "sample-range-2" = {
    address       = "" # Left blank, GCP will auto-allocate a range automatically
    prefix_length = 24
  }

}
# -------------------------------------------
# MAP OF DYNAMIC SUBNETS - We can put as many subnets as we want here 
# -------------------------------------------
subnets = {

  "example-subnet-1" = {
    region             = "asia-southeast1"
    cidr               = "10.238.19.128/25"
    service_project_id = "ornate-node-483516-e3"
  },

  "example-subnet-2" = {
    region             = "asia-southeast1"
    cidr               = "10.238.19.0/26"
    service_project_id = "ornate-node-483516-e3" # Can share multiple subnets to the same project
  }

  # "another-team-subnet" = {
  #   region             = "asia-southeast1"
  #   cidr               = "10.238.20.0/24"
  #   service_project_id = "some-other-project-123" # Can share to entirely different projects!
  # }
}

# -------------------------------------------
# BASELINE FIREWALL RULES
# -------------------------------------------
firewall_rules = {
  "allow-internal-traffic" = {
    direction = "INGRESS"
    action    = "allow"
    priority  = 1000
    ranges    = ["10.238.19.0/24"] # Expanded to cover both subnets
    rules     = [{ protocol = "all", ports = [] }]
  }
}