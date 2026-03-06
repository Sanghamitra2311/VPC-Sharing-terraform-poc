variable "host_project_id" { type = string }
variable "network_name" { type = string }

# ==========================================
# DYNAMIC SUBNETS & SERVICE PROJECTS MAP
# ==========================================
variable "subnets" {
  description = "Map of subnets to create and share with specific service projects"
  type = map(object({
    region             = string
    cidr               = string
    service_project_id = string
  }))
}

# ==========================================
# OPTIONAL: PRIVATE SERVICE ACCESS (PSA)
# ==========================================
# ==========================================
# OPTIONAL: PRIVATE SERVICE ACCESS (PSA) RANGES
# ==========================================
variable "create_psa" {
  description = "Master toggle to enable or disable PSA creation entirely."
  type        = bool
  default     = false
}
variable "psa_ranges" {
  description = "Map of Private Service Access (PSA) IP allocations"
  type = map(object({
    address       = optional(string, "") # Leave blank ("") to let GCP auto-allocate
    prefix_length = number
  }))
  default = {}
}
# ==========================================
# FIREWALL RULES (UNIFIED ENGINE SCHEMA)
# ==========================================
variable "firewall_rules" {
  description = "Unified map of all custom firewall rules"
  type = map(object({
    direction               = string
    action                  = string
    priority                = number
    ranges                  = list(string)
    target_tags             = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    rules = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
  default = {}
}