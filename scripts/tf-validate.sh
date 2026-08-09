#!/usr/bin/env bash
################################################################################
# tf-validate.sh
# Initializes (backend-free) and validates a Terraform stack.
# Does NOT require cloud credentials — purely syntax + config validation.
#
# Usage: ./scripts/tf-validate.sh <stack_name>
# Example: ./scripts/tf-validate.sh iam
################################################################################

set -euo pipefail

STACK_NAME="${1:?Usage: $0 <stack_name>}"
STACK_DIR="stacks/${STACK_NAME}"

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

echo "──────────────────────────────────────────"
echo "🔍 Validating stack: ${STACK_NAME}"
echo "──────────────────────────────────────────"

# Initialize without backend to avoid needing AWS credentials
echo "→ Running terraform init -backend=false..."
terraform -chdir="${STACK_DIR}" init -backend=false -input=false -no-color

# Validate
echo "→ Running terraform validate..."
if terraform -chdir="${STACK_DIR}" validate -no-color; then
  echo "✅ Validation passed for stack: ${STACK_NAME}"
else
  echo "❌ Validation failed for stack: ${STACK_NAME}"
  exit 1
fi
