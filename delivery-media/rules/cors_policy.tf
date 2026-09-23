data "akamai_property_rules_builder" "rule_cors_policy" {
  count = var.enable_cors_policy ? 1 : 0

  rules_v2026_02_16 {
    name                  = "Default CORS Policy"
    criteria_must_satisfy = "all"

    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_allow_origin
        standard_modify_header_name = "ACCESS_CONTROL_ALLOW_ORIGIN"
      }
    }
    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_allow_methods
        standard_modify_header_name = "ACCESS_CONTROL_ALLOW_METHODS"
      }
    }
    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_allow_headers
        standard_modify_header_name = "ACCESS_CONTROL_ALLOW_HEADERS"
      }
    }
    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_expose_headers
        standard_modify_header_name = "ACCESS_CONTROL_EXPOSE_HEADERS"
      }
    }
    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_allow_credentials
        standard_modify_header_name = "ACCESS_CONTROL_ALLOW_CREDENTIALS"
      }
    }
    behavior {
      modify_outgoing_response_header {
        action                      = "MODIFY"
        avoid_duplicate_headers     = false
        new_header_value            = var.cors_max_age
        standard_modify_header_name = "ACCESS_CONTROL_MAX_AGE"
      }
    }
  }
}
