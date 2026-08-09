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

# Resolve repo root (where .tflint.hcl lives)
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/.tflint.hcl"

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "⚠️  Warning: .tflint.hcl not found at ${CONFIG_FILE}, running without config."
  CONFIG_FLAG=""
else
  CONFIG_FLAG="--config=${CONFIG_FILE}"
fi

echo "──────────────────────────────────────────"
echo "🔍 Linting stack: ${STACK_NAME}"
echo "──────────────────────────────────────────"

# Install tflint if not present
if ! command -v tflint &>/dev/null; then
  echo "→ Installing tflint..."
  curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi

# Initialize tflint plugins (run from the stack dir with absolute config path)
echo "→ Initializing tflint plugins..."
cd "${STACK_DIR}"
tflint --init ${CONFIG_FLAG}

# Run tflint
echo "→ Running tflint..."
if tflint ${CONFIG_FLAG} --format=compact; then
  echo "✅ Linting passed for stack: ${STACK_NAME}"
else
  echo "⚠️  Linting issues found in stack: ${STACK_NAME}"
  exit 1
fi
