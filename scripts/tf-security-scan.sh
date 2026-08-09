#!/usr/bin/env bash
################################################################################
# tf-security-scan.sh
# Runs tfsec (or trivy) on a given stack directory for security scanning.
#
# Usage: ./scripts/tf-security-scan.sh <stack_name>
# Example: ./scripts/tf-security-scan.sh alb
################################################################################

set -euo pipefail

STACK_NAME="${1:?Usage: $0 <stack_name>}"
STACK_DIR="stacks/${STACK_NAME}"

if [[ ! -d "${STACK_DIR}" ]]; then
  echo "❌ Error: Stack directory '${STACK_DIR}' not found."
  exit 1
fi

echo "──────────────────────────────────────────"
echo "🔒 Security scan: ${STACK_NAME}"
echo "──────────────────────────────────────────"

# Prefer trivy (tfsec successor), fall back to tfsec
if command -v trivy &>/dev/null; then
  echo "→ Running trivy config scan..."
  trivy config "${STACK_DIR}" \
    --severity HIGH,CRITICAL \
    --exit-code 1 \
    --format table
  SCAN_EXIT=$?
elif command -v tfsec &>/dev/null; then
  echo "→ Running tfsec scan..."
  tfsec "${STACK_DIR}" \
    --minimum-severity HIGH \
    --format lovely
  SCAN_EXIT=$?
else
  echo "⚠️  Neither trivy nor tfsec found. Installing trivy..."
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
  trivy config "${STACK_DIR}" \
    --severity HIGH,CRITICAL \
    --exit-code 1 \
    --format table
  SCAN_EXIT=$?
fi

if [[ "${SCAN_EXIT}" -eq 0 ]]; then
  echo "✅ Security scan passed for stack: ${STACK_NAME}"
else
  echo "❌ Security issues found in stack: ${STACK_NAME}"
  exit 1
fi
