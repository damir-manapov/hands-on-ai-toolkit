#!/bin/sh
set -e

echo "=========================================="
echo "Running all checks"
echo "=========================================="

./check.sh
./terraform/check.sh
./security.sh
./renovate-check.sh

echo "=========================================="
echo "All checks completed successfully"
echo "=========================================="
