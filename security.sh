#!/bin/sh
set -e

echo "=== Security: gitleaks ==="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . -v
  echo "=== Security checks passed ==="
  exit 0
fi

if [ "${STRICT_SECURITY:-0}" = "1" ]; then
  echo "gitleaks is not installed (STRICT_SECURITY=1)"
  exit 1
fi

echo "gitleaks is not installed, skipping (set STRICT_SECURITY=1 to fail)"
