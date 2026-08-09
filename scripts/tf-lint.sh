#!/usr/bin/env bash
################################################################################
# tf-lint.sh
# Runs tflint on a given stack directory using the shared .tflint.hcl config.
#
# Usage: ./scripts/tf-lint.sh <stack_name>
# Example: ./scripts/tf-lint.sh ecr
################################################################################

set -euo pipefail

STACK_NAME="${1:?Usage: $0 <stack_name>}"
STACK_DIR="stacks/${STACK_NAME}"
CONFIG_FILE=".tflint.hcl"

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

echo "──────────────────────────────────────────"
echo "🔍 Linting stack: ${STACK_NAME}"
echo "──────────────────────────────────────────"

# Install tflint if not present
if ! command -v tflint &>/dev/null; then
  echo "→ Installing tflint..."
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi

# Initialize tflint plugins
echo "→ Initializing tflint plugins..."
tflint --init --config="${CONFIG_FILE}" --chdir="${STACK_DIR}"

# Run tflint
echo "→ Running tflint..."
if tflint --config="../../${CONFIG_FILE}" --chdir="${STACK_DIR}" --format=compact; then
  echo "✅ Linting passed for stack: ${STACK_NAME}"
else
  echo "⚠️  Linting issues found in stack: ${STACK_NAME}"
  exit 1
fi
