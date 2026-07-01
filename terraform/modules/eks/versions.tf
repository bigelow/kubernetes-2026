# Requires Terraform 1.9+ for cross-variable validation (min <= desired <= max
# in variables.tf references sibling variables).
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    # Used to derive the OIDC issuer thumbprint for the IRSA provider (b5).
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}
