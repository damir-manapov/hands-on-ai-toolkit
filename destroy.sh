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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform/selectel"
DEFAULT_PRESET="terraform.tfvars.moscow-4080"
VAR_FILE="${1:-$DEFAULT_PRESET}"

# ── Preflight ──────────────────────────────────────────────────
check_env() {
  local missing=()
  for var in TF_VAR_selectel_domain TF_VAR_selectel_username \
             TF_VAR_selectel_password TF_VAR_selectel_openstack_password; do
    if [ -z "${!var:-}" ]; then
      missing+=("$var")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required environment variables:"
    printf "  %s\n" "${missing[@]}"
    exit 1
  fi
}

check_env

if ! command -v terraform &>/dev/null; then
  echo "ERROR: terraform is required but not found in PATH"
  exit 1
fi

if [ ! -f "$TF_DIR/$VAR_FILE" ]; then
  echo "ERROR: Var file not found: $TF_DIR/$VAR_FILE"
  exit 1
fi

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
terraform destroy -var-file="$VAR_FILE" -auto-approve

echo ""
echo "=== Infrastructure destroyed ==="
