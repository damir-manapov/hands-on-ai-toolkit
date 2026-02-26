#!/usr/bin/env bash
# Shared helpers for provision.sh / destroy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform/selectel"
DEFAULT_PRESET="terraform.tfvars.moscow-4080"

# ── Env check ──────────────────────────────────────────────────
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
    echo ""
    echo "Export them before running:"
    echo '  export TF_VAR_selectel_domain="..."'
    echo '  export TF_VAR_selectel_username="..."'
    echo '  export TF_VAR_selectel_password="..."'
    echo '  export TF_VAR_selectel_openstack_password="..."'
    exit 1
  fi
}

# ── Tool check ─────────────────────────────────────────────────
check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo "ERROR: $1 is required but not found in PATH"
    exit 1
  fi
}

# ── Resolve var file ───────────────────────────────────────────
resolve_var_file() {
  local var_file="${1:-$DEFAULT_PRESET}"
  if [ ! -f "$TF_DIR/$var_file" ]; then
    echo "ERROR: Var file not found: $TF_DIR/$var_file"
    echo "Available presets:"
    ls "$TF_DIR"/terraform.tfvars.* 2>/dev/null | sed 's|.*/||' || echo "  (none)"
    exit 1
  fi
  echo "$var_file"
}
