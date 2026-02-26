#!/bin/sh
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/terraform"

echo "=== Terraform: format (selectel) ==="
if [ -d "selectel" ]; then
  (cd selectel && terraform fmt)
fi

echo ""
echo "=== Terraform: validate (selectel, if initialized) ==="
if [ -d "selectel/.terraform" ]; then
  (cd selectel && terraform validate)
else
  echo "selectel/.terraform not found, skipping validate"
fi

echo ""
echo "=== Terraform: tflint (optional) ==="
if command -v tflint >/dev/null 2>&1; then
  tflint --init
  tflint --recursive
else
  echo "tflint not installed, skipping"
fi

echo ""
echo "=== Terraform: trivy config scan (optional) ==="
if command -v trivy >/dev/null 2>&1; then
  trivy config --severity HIGH,CRITICAL .
else
  echo "trivy not installed, skipping"
fi

echo ""
echo "=== Terraform checks passed ==="
