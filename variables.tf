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
# FIREWALL RULE LISTS (Protocols & Ports)
# ==========================================
variable "allow_rules" {
  description = "List of dynamic allow ingress rules (protocol and ports)"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

variable "deny_rules" {
  description = "List of dynamic deny ingress rules (protocol and ports)"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

variable "allow_egress_rules" {
  description = "List of dynamic allow egress rules (protocol and ports)"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

variable "deny_egress_rules" {
  description = "List of dynamic deny egress rules (protocol and ports)"
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default = []
}

# ==========================================
# FIREWALL TARGETS (Applies to all rules)
# ==========================================
variable "firewall_target_tags" {
  description = "List of target tags for firewall rules"
  type        = list(string)
  default     = []
}

variable "firewall_target_service_accounts" {
  description = "List of target service accounts for firewall rules"
  type        = list(string)
  default     = []
}

# ==========================================
# FIREWALL SOURCE & DESTINATION RANGES
# ==========================================
variable "allow_source_ranges" {
  description = "List of source IP ranges for allow ingress rules"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "deny_source_ranges" {
  description = "List of source IP ranges for deny ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_egress_destination_ranges" {
  description = "List of destination IP ranges for allow egress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deny_egress_destination_ranges" {
  description = "List of destination IP ranges for deny egress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}