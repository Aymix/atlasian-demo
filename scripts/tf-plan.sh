#!/usr/bin/env bash
################################################################################
# tf-plan.sh
# Runs terraform init + plan on a given stack.
# Saves the plan output to a file for review/apply.
# Requires AWS credentials to be configured.
#
# Usage: ./scripts/tf-plan.sh <stack_name> [extra_args...]
# Example: ./scripts/tf-plan.sh vpc -var="environment=staging"
################################################################################

set -euo pipefail

STACK_NAME="${1:?Usage: $0 <stack_name> [extra_args...]}"
STACK_DIR="stacks/${STACK_NAME}"
PLAN_DIR=".plans"
shift # remaining args passed to terraform plan

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

# Create plans output directory
mkdir -p "${PLAN_DIR}"
PLAN_FILE="${PLAN_DIR}/${STACK_NAME}.tfplan"

echo "──────────────────────────────────────────"
echo "📋 Planning stack: ${STACK_NAME}"
echo "──────────────────────────────────────────"

# Initialize
echo "→ Running terraform init..."
terraform -chdir="${STACK_DIR}" init -input=false -no-color

# Plan
echo "→ Running terraform plan..."
terraform -chdir="${STACK_DIR}" plan \
  -input=false \
  -no-color \
  -out="../../${PLAN_FILE}" \
  "$@"

echo ""
echo "✅ Plan saved to: ${PLAN_FILE}"
echo "   To apply: terraform -chdir=${STACK_DIR} apply ../../${PLAN_FILE}"
