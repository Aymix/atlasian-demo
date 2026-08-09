#!/usr/bin/env bash
################################################################################
# detect-changed-stacks.sh
# Detects which Terraform stacks have changed in the current PR/branch
# compared to the base branch. Outputs a JSON array for GHA matrix strategy.
#
# Usage: ./scripts/detect-changed-stacks.sh [base_branch]
# Output: JSON array, e.g. ["vpc","iam","ecs"]
################################################################################

set -euo pipefail

BASE_BRANCH="${1:-origin/main}"
STACKS_DIR="stacks"

# Get list of changed files relative to base branch
CHANGED_FILES=$(git diff --name-only "${BASE_BRANCH}"...HEAD 2>/dev/null || \
                git diff --name-only "${BASE_BRANCH}" HEAD 2>/dev/null || \
                echo "")

if [[ -z "${CHANGED_FILES}" ]]; then
  echo "[]"
  exit 0
fi

# Extract unique stack directory names from changed files
CHANGED_STACKS=$(echo "${CHANGED_FILES}" | \
  grep "^${STACKS_DIR}/" | \
  cut -d'/' -f2 | \
  sort -u)

if [[ -z "${CHANGED_STACKS}" ]]; then
  echo "[]"
  exit 0
fi

# Build JSON array
JSON="["
FIRST=true
while IFS= read -r stack; do
  # Verify the stack directory actually exists
  if [[ -d "${STACKS_DIR}/${stack}" ]]; then
    if [[ "${FIRST}" == "true" ]]; then
      JSON+="\"${stack}\""
      FIRST=false
    else
      JSON+=",\"${stack}\""
    fi
  fi
done <<< "${CHANGED_STACKS}"
JSON+="]"

echo "${JSON}"
