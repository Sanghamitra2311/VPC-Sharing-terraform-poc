variable "host_project_id" { type = string }
variable "service_project_id" { type = string }
variable "region" { type = string }
variable "network_name" { type = string }
variable "subnet_name" { type = string }
variable "subnet_cidr" { type = string }

# ==========================================
# OPTIONAL: PRIVATE SERVICE ACCESS (PSA)
# ==========================================
variable "create_psa" {
  type    = bool
  default = false
}

variable "psa_prefix_length" {
  type    = number
  default = 24
}

# ==========================================
# FIREWALL RULES (UNIFIED ENGINE SCHEMA)
# ==========================================
variable "firewall_rules" {
  description = "Unified map of all custom firewall rules"
  type = map(object({
    direction               = string # "INGRESS" or "EGRESS"
    action                  = string # "allow" or "deny"
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