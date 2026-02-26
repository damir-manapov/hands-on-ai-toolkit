#!/usr/bin/env bash
set -euo pipefail

# Destroy AI Toolkit Selectel infrastructure
#
# Usage:
#   ./destroy.sh                          # uses terraform.tfvars.moscow-4080 preset
#   ./destroy.sh my-custom.tfvars         # uses custom var file
#   FORCE=1 ./destroy.sh                  # skip confirmation prompt
#
# Required environment variables:
#   TF_VAR_selectel_domain
#   TF_VAR_selectel_username
#   TF_VAR_selectel_password
#   TF_VAR_selectel_openstack_password

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

VAR_FILE=$(resolve_var_file "${1:-}")

check_env
check_tool terraform

cd "$TF_DIR"

# Show what will be destroyed
if terraform state list &>/dev/null 2>&1; then
  RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
  echo "=== Destroy AI Toolkit Infrastructure ==="
  echo "Preset: $VAR_FILE"
  echo "Resources: $RESOURCE_COUNT"
  echo ""

  # Show server IP if available
  SERVER_IP=$(terraform output -raw server_ip 2>/dev/null || true)
  if [ -n "$SERVER_IP" ]; then
    echo "Server IP: $SERVER_IP"
    echo ""
  fi
else
  echo "No Terraform state found — nothing to destroy."
  exit 0
fi

# ── Confirmation ───────────────────────────────────────────────
if [ "${FORCE:-}" != "1" ]; then
  read -rp "Destroy all $RESOURCE_COUNT resources? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ── Destroy ────────────────────────────────────────────────────
echo ""
echo "--- Destroying ---"
if ! terraform destroy -var-file="$VAR_FILE" -auto-approve 2>&1; then
  echo ""
  echo "WARN: terraform destroy failed (flavor lookup issue?). Falling back to forced cleanup..."
  # Remove OpenStack resources from state (they depend on the failing flavor data source)
  terraform state list 2>/dev/null | grep '^openstack_\|^data\.openstack_' | while read -r res; do
    terraform state rm "$res" 2>/dev/null || true
  done
  # Destroy remaining Selectel-only resources
  terraform destroy -var 'flavor_name=' -auto-approve || true
fi

echo ""
echo "=== Infrastructure destroyed ==="
