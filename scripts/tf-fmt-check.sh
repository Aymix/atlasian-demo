#!/usr/bin/env bash
################################################################################
# tf-fmt-check.sh
# Runs `terraform fmt -check -diff` on a given stack directory.
# Exits non-zero if formatting drift is found.
#
# Usage: ./scripts/tf-fmt-check.sh <stack_name>
# Example: ./scripts/tf-fmt-check.sh vpc
################################################################################

set -euo pipefail

STACK_NAME="${1:?Usage: $0 <stack_name>}"
STACK_DIR="stacks/${STACK_NAME}"

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

echo "──────────────────────────────────────────"
echo "🔍 Checking formatting: ${STACK_NAME}"
echo "──────────────────────────────────────────"

if terraform fmt -check -diff -recursive "${STACK_DIR}"; then
  echo "✅ Formatting OK for stack: ${STACK_NAME}"
else
  echo "❌ Formatting issues found in stack: ${STACK_NAME}"
  echo "   Run 'terraform fmt -recursive ${STACK_DIR}' to fix."
  exit 1
fi
