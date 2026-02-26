#!/bin/sh
set -e

echo "=== Health: gitleaks ==="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . -v
else
  echo "gitleaks not installed, skipping (install: https://github.com/gitleaks/gitleaks)"
fi

echo ""
echo "=== Health: renovate dependency freshness ==="
./renovate-check.sh

echo ""
echo "=== Health check passed ==="
