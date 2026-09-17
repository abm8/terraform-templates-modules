terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = "~> 10.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  required_version = ">= 1.9.0"
}
