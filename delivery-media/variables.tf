### Scope ##############################################################

variable "contract_id" {
  description = "Akamai contract ID (e.g. ctr_1-AB123)."
  type        = string
}

variable "group_id" {
  description = "Akamai group ID (e.g. grp_12345)."
  type        = string
}

variable "product_id" {
  description = "Akamai product ID for this property."
  type        = string
  default     = "prd_Adaptive_Media_Delivery"
}

variable "name" {
  description = "Property name."
  type        = string
}

variable "version_notes" {
  description = "Property version notes."
  type        = string
  default     = "Initial Config"
}

### CP code #############################################################

variable "cpcode_name" {
  description = "Name for the CP code created for this property. Defaults to the property name if not set."
  type        = string
  default     = null
}

### Hostnames ############################################################

variable "hostnames" {
  description = <<-EOT
    List of hostnames, e.g. ["www.example.com", "media.example.com"].
    For SBD with etls=true, Akamai provisions the edgekey.net hostname
    automatically. For SBD with etls=false, EDGESUITE, and EDGEKEY, each
    entry is your own domain and its edge hostname is created as needed. For
    AKAMAIZED_HOSTNAME, each entry is just a label (e.g. "abm-template-test")
    -- the .akamaized.net suffix is appended automatically and used as both
    cname_from and cname_to.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.hostnames) > 0 && length(distinct(var.hostnames)) == length(var.hostnames)
    error_message = "hostnames must contain at least one unique hostname."
  }

  validation {
    condition = alltrue([
      for h in var.hostnames : (
        var.edge_hostname_type == "AKAMAIZED_HOSTNAME"
        ? length(h) >= 4 && length(h) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", h))
        : length(h) <= 253 && alltrue([
          for label in split(".", h) :
          length(label) >= 1 && length(label) <= 63 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", label))
        ])
      )
    ])
    error_message = "hostnames must be lowercase valid DNS names; AKAMAIZED_HOSTNAME values must be 4-63 character labels."
  }
}

variable "edge_hostname_type" {
  description = "Edge hostname mode: SBD (Secure By Default, no cert needed), EDGESUITE (aka Freeflow, <hostname>.edgesuite.net), EDGEKEY (aka ESSL, <hostname>.edgekey.net), or AKAMAIZED_HOSTNAME (<label>.akamaized.net, hostname and edge hostname are identical)."
  type        = string
  default     = "AKAMAIZED_HOSTNAME"

  validation {
    condition     = contains(["SBD", "EDGESUITE", "EDGEKEY", "AKAMAIZED_HOSTNAME"], var.edge_hostname_type)
    error_message = "edge_hostname_type must be one of SBD, EDGESUITE, EDGEKEY, AKAMAIZED_HOSTNAME."
  }

  validation {
    condition = (
      var.edge_hostname_type == "SBD" ||
      (var.edge_hostname_type == "EDGESUITE" && !var.etls) ||
      (var.edge_hostname_type == "EDGEKEY" && var.etls) ||
      var.edge_hostname_type == "AKAMAIZED_HOSTNAME"
    )
    error_message = "Use etls=false with EDGESUITE, etls=true with EDGEKEY, and either value with SBD or AKAMAIZED_HOSTNAME."
  }

}

variable "certificate_id" {
  description = "CPS certificate enrollment ID. Required only when edge_hostname_type is EDGEKEY."
  type        = number
  default     = null

  validation {
    condition     = var.edge_hostname_type != "EDGEKEY" || var.certificate_id != null
    error_message = "certificate_id is required when edge_hostname_type is EDGEKEY."
  }
}

variable "ip_behavior" {
  description = "IP version behavior for the edge hostname: IPV4, IPV6_COMPLIANCE, or IPV6_PERFORMANCE."
  type        = string
  default     = "IPV4"
}

### Activation ############################################################

variable "activate_to_staging" {
  description = "Whether to activate the property to the staging network."
  type        = bool
  default     = false
}

variable "activate_to_production" {
  description = "Whether to activate the property to the production network."
  type        = bool
  default     = false
}

variable "activation_to_staging_exists" {
  description = "Do not modify. Preserves the existing staging activation when activate_to_staging is false."
  type        = bool
  default     = false
}

variable "activation_to_production_exists" {
  description = "Do not modify. Preserves the existing production activation when activate_to_production is false."
  type        = bool
  default     = false
}

variable "activation_notes" {
  description = "Notes attached to each activation."
  type        = string
  default     = "Activated via Terraform"
}

variable "activation_contacts" {
  description = "Email addresses notified on activation."
  type        = list(string)
}

### Production compliance / change-management #############################
# Mirrors the ION new-property compliance_record pattern: required fields
# vary by noncompliance_reason when activating straight to production.

variable "noncompliance_reason" {
  description = "Compliance record marker for production activation. Allowed values: NONE, OTHER, NO_PRODUCTION_TRAFFIC, EMERGENCY. Required (exactly one value) when activate_to_production is true."
  type        = list(string)
  default     = []

  validation {
    condition = (
      !var.activate_to_production ||
      (
        length(var.noncompliance_reason) == 1 &&
        (
          contains(var.noncompliance_reason, "NONE") ||
          contains(var.noncompliance_reason, "OTHER") ||
          contains(var.noncompliance_reason, "NO_PRODUCTION_TRAFFIC") ||
          contains(var.noncompliance_reason, "EMERGENCY")
        )
      )
    )
    error_message = "When activate_to_production is true, noncompliance_reason must contain exactly one of NONE, OTHER, NO_PRODUCTION_TRAFFIC, EMERGENCY."
  }
}

variable "ticket_id" {
  description = "Change/ticket ID. Required whenever activate_to_production is true (all four reasons require it)."
  type        = string
  default     = null

  validation {
    condition     = !var.activate_to_production || var.ticket_id != null
    error_message = "ticket_id is required when activate_to_production is true."
  }
}

variable "other_noncompliance_reason" {
  description = "Free-text explanation. Required when noncompliance_reason is [\"OTHER\"]."
  type        = string
  default     = null

  validation {
    condition     = !var.activate_to_production || !contains(var.noncompliance_reason, "OTHER") || var.other_noncompliance_reason != null
    error_message = "other_noncompliance_reason is required when noncompliance_reason is [\"OTHER\"]."
  }
}

variable "peer_reviewed_by" {
  description = "Peer reviewer identity. Required when noncompliance_reason is [\"NONE\"] (i.e. full standard review trail, no exception being invoked)."
  type        = string
  default     = null

  validation {
    condition     = !var.activate_to_production || !contains(var.noncompliance_reason, "NONE") || var.peer_reviewed_by != null
    error_message = "peer_reviewed_by is required when noncompliance_reason is [\"NONE\"]."
  }
}

variable "customer_email" {
  description = "Customer contact email. Required when noncompliance_reason is [\"NONE\"]."
  type        = string
  default     = null

  validation {
    condition     = !var.activate_to_production || !contains(var.noncompliance_reason, "NONE") || var.customer_email != null
    error_message = "customer_email is required when noncompliance_reason is [\"NONE\"]."
  }
}

variable "unit_tested" {
  description = "Whether the change has been unit tested. Required when noncompliance_reason is [\"NONE\"]."
  type        = bool
  default     = null

  validation {
    condition     = !var.activate_to_production || !contains(var.noncompliance_reason, "NONE") || var.unit_tested != null
    error_message = "unit_tested is required when noncompliance_reason is [\"NONE\"]."
  }
}

### Rules passthrough (forwarded to the rules submodule) ##################

variable "etls" {
  description = "Security profile selector: SBD uses edgekey.net when true or edgesuite.net when false; EDGEKEY and AKAMAIZED_HOSTNAME require true; EDGESUITE requires false."
  type        = bool
  default     = true
}

variable "default_origin" {
  type = string
}

variable "additional_origins" {
  description = "Optional additional origins selected by hostname and/or path criteria."
  type = map(object({
    origin_name         = string
    forward_host_header = string
    hostname_match      = list(string)
    path_match          = list(string)
  }))
  default = {}
}

variable "forward_host_header" {
  type    = string
  default = "REQUEST_HOST_HEADER"
}

variable "http2_enabled" {
  type    = bool
  default = true
}

variable "min_tls_version" {
  type    = string
  default = "DYNAMIC"
}

variable "verification_mode" {
  type    = string
  default = "PLATFORM_SETTINGS"
}

variable "segmented_media_optimization_behavior" {
  type    = string
  default = "ON_DEMAND"
}

variable "origin_authentication_method" {
  type    = string
  default = "AUTOMATIC"
}

variable "origin_country" {
  type    = string
  default = "UNKNOWN"
}

variable "client_country" {
  type    = string
  default = "UNKNOWN"
}

variable "content_catalog_size" {
  type    = string
  default = "UNKNOWN"
}

variable "content_type" {
  type    = string
  default = "HD"
}

variable "content_popularity_distribution" {
  type    = string
  default = "UNKNOWN"
}

variable "enable_dash" {
  type    = bool
  default = true
}

variable "enable_hds" {
  type    = bool
  default = true
}

variable "enable_hls" {
  type    = bool
  default = true
}

variable "enable_smooth" {
  type    = bool
  default = true
}

variable "segment_duration_dash" {
  type    = string
  default = "SEGMENT_DURATION_6S"
}

variable "segment_duration_hds" {
  type    = string
  default = "SEGMENT_DURATION_6S"
}

variable "segment_duration_hls" {
  type    = string
  default = "SEGMENT_DURATION_10S"
}

variable "segment_duration_smooth" {
  type    = string
  default = "SEGMENT_DURATION_2S"
}

variable "cache_key_query_params_behavior" {
  type    = string
  default = "IGNORE_ALL"
}

variable "enable_dynamic_throughput_optimization" {
  type    = bool
  default = true
}

variable "enable_http3" {
  type    = bool
  default = true
}

variable "enable_segmented_content_protection" {
  type    = bool
  default = false
}

variable "dash_media_encryption" {
  type    = bool
  default = false
}

variable "hls_media_encryption" {
  type    = bool
  default = false
}

variable "enable_debug" {
  type    = bool
  default = true
}

variable "debug_key" {
  description = "Optional enhanced-debug key. If omitted while debug is enabled, Terraform generates a stable key."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.debug_key == null || can(regex("^[0-9a-fA-F]{64}$", var.debug_key))
    error_message = "debug_key must be exactly 64 hexadecimal characters."
  }
}

variable "enable_cors_policy" {
  type    = bool
  default = true
}

variable "cors_allow_origin" {
  type    = string
  default = "*"
}

variable "cors_allow_methods" {
  type    = string
  default = "GET,POST,OPTIONS"
}

variable "cors_allow_headers" {
  type    = string
  default = "origin,range,hdntl,hdnts,CMCD-Request,CMCD-Object,CMCD-Status,CMCD-Session"
}

variable "cors_expose_headers" {
  type    = string
  default = "Server,range,hdntl,hdnts,Akamai-Mon-Iucid-Ing,Akamai-Mon-Iucid-Del,Akamai-Request-BC"
}

variable "cors_allow_credentials" {
  type    = string
  default = "true"
}

variable "cors_max_age" {
  type    = string
  default = "86400"
}
