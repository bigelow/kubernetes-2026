config {
  # Lint module call blocks and referenced modules too.
  call_module_type = "all"
}

# Core Terraform rules (terraform_*): documentation, naming, unused decls,
# deprecated syntax, required_version/providers, etc.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# AWS resource rules — invalid instance types, missing required args, insecure
# defaults. Pinned so CI is reproducible.
plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
