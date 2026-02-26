#!/usr/bin/env bash
set -euo pipefail

# Provision AI Toolkit on Selectel
#
# Usage:
#   ./provision.sh                          # uses terraform.tfvars.moscow-4080 preset
#   ./provision.sh my-custom.tfvars         # uses custom var file
#
# Required environment variables:
#   TF_VAR_selectel_domain
#   TF_VAR_selectel_username
#   TF_VAR_selectel_password
#   TF_VAR_selectel_openstack_password
#
# Optional:
#   TF_VAR_ai_toolkit_auth   – auth token for the UI

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

VAR_FILE=$(resolve_var_file "${1:-}")

check_env
check_tool terraform

echo "=== Provisioning AI Toolkit ==="
echo "Preset: $VAR_FILE"
echo "Terraform dir: $TF_DIR"
echo ""

# ── Terraform init + apply ─────────────────────────────────────
cd "$TF_DIR"

terraform init -input=false

echo ""
echo "--- Planning ---"
terraform plan -var-file="$VAR_FILE" -out=tfplan -input=false

echo ""
echo "--- Applying ---"
terraform apply -input=false tfplan

# ── Extract outputs ────────────────────────────────────────────
SERVER_IP=$(terraform output -raw server_ip)
SSH_CMD=$(terraform output -raw ssh_command)
UI_URL=$(terraform output -raw ui_url)

echo ""
echo "=== Server created ==="
echo "IP:  $SERVER_IP"
echo "SSH: $SSH_CMD"
echo "UI:  $UI_URL"

# ── Wait for cloud-init ───────────────────────────────────────
echo ""
echo "--- Waiting for cloud-init to finish (NVIDIA driver + Docker + AI Toolkit) ---"
echo "This usually takes 5-10 minutes for GPU setup..."

# Wait for SSH to become available
for i in $(seq 1 30); do
  if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@$SERVER_IP" 'true' 2>/dev/null; then
    break
  fi
  echo "  Waiting for SSH... ($i/30)"
  sleep 10
done

# Wait for cloud-init-ready marker
ssh -o StrictHostKeyChecking=no "root@$SERVER_IP" \
  'while [ ! -f /root/cloud-init-ready ]; do echo "  cloud-init still running..."; sleep 15; done'

echo ""
echo "--- Verifying GPU ---"
if ssh "root@$SERVER_IP" 'nvidia-smi' 2>/dev/null; then
  echo ""
  echo "--- Verifying container GPU ---"
  ssh "root@$SERVER_IP" 'docker exec ai-toolkit nvidia-smi' 2>/dev/null || echo "WARN: GPU not visible inside container yet (may need a moment)"
else
  echo "WARN: nvidia-smi not available — GPU driver may still be loading"
fi

echo ""
echo "--- Checking AI Toolkit UI ---"
if curl -sS --connect-timeout 10 -o /dev/null -w "%{http_code}" "$UI_URL" | grep -q "200"; then
  echo "UI is UP at $UI_URL"
else
  echo "WARN: UI not responding yet at $UI_URL — check in a minute"
fi

echo ""
echo "=== Provisioning complete ==="
echo "SSH: $SSH_CMD"
echo "UI:  $UI_URL"
echo ""
echo "To destroy: ./destroy.sh"
