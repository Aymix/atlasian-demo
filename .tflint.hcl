################################################################################
# TFLint Configuration
# Shared config used across all stacks via scripts/tf-lint.sh
# Docs: https://github.com/terraform-linters/tflint
################################################################################

config {
  # Enable all available rules by default
  force = false

  # Call modules for deep inspection
  call_module_type = "local"
}

# ── AWS Plugin ─────────────────────────────────────────────────────────────

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# ── Rules ──────────────────────────────────────────────────────────────────

# Disallow deprecated (0.11-style) interpolation
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Require all outputs to have descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Require all variables to have descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow terraform.workspace usage (not meaningful in CI)
rule "terraform_workspace_remote" {
  enabled = true
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Require type declarations on variables
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Require required_version in terraform block
rule "terraform_required_version" {
  enabled = true
}

# Require required_providers in terraform block
rule "terraform_required_providers" {
  enabled = true
}
