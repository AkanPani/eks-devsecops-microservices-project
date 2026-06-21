#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_DIR="terraform"
PLAN_JSON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --terraform-dir) TERRAFORM_DIR="$2"; shift 2 ;;
    --plan-json) PLAN_JSON="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

mkdir -p reports/checkov

echo "Running Checkov Terraform code scan..."
checkov \
  -d "${TERRAFORM_DIR}" \
  --framework terraform \
  --output cli \
  --output json \
  --output-file-path console,reports/checkov/checkov-terraform.json

if [[ -n "${PLAN_JSON}" && -f "${PLAN_JSON}" ]]; then
  echo "Running Checkov Terraform plan scan..."
  checkov \
    -f "${PLAN_JSON}" \
    --framework terraform_plan \
    --output cli \
    --output json \
    --output-file-path console,reports/checkov/checkov-tfplan.json
else
  echo "Plan JSON not found. Skipping Terraform plan scan."
fi

echo "Checkov scan completed."
