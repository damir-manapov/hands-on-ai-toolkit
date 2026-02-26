#!/bin/sh
set -e

PRELOAD_SCRIPT=$(mktemp)
echo "require('net').setDefaultAutoSelectFamily(false);" > "$PRELOAD_SCRIPT"
trap "rm -f $PRELOAD_SCRIPT" EXIT
export NODE_OPTIONS="${NODE_OPTIONS:-} --require=$PRELOAD_SCRIPT --dns-result-order=ipv4first"

echo "=== Running Renovate dependency check (docker-compose + terraform) ==="

OUTPUT=$(LOG_FORMAT=json LOG_LEVEL=debug npx -y renovate --platform=local --dry-run 2>&1 || true)

if echo "$OUTPUT" | grep -q '"result":"external-host-error"'; then
  echo "⚠ Renovate couldn't reach external hosts (network issue)"
  exit 2
fi

BRANCHES_INFO=$(echo "$OUTPUT" | grep '"branchesInformation"' || true)

if [ -z "$BRANCHES_INFO" ]; then
  echo "✓ No outdated docker/terraform dependencies found"
  exit 0
fi

MAJOR_COUNT=$(echo "$BRANCHES_INFO" | grep -o '"updateType":"major"' | wc -l)
MINOR_COUNT=$(echo "$BRANCHES_INFO" | grep -o '"updateType":"minor"' | wc -l)
PATCH_COUNT=$(echo "$BRANCHES_INFO" | grep -o '"updateType":"patch"' | wc -l)

if [ "$MAJOR_COUNT" -eq 0 ] && [ "$MINOR_COUNT" -eq 0 ] && [ "$PATCH_COUNT" -eq 0 ]; then
  echo "✓ No outdated docker/terraform dependencies found"
  exit 0
fi

echo ""
echo "Outdated dependencies detected:"
echo "$BRANCHES_INFO" | grep -oE '\{"branchName":"[^}]+\}' | while read -r branch; do
  DEP_NAME=$(echo "$branch" | grep -oE '"depName":"[^"]+' | cut -d'"' -f4)
  CURRENT=$(echo "$branch" | grep -oE '"currentVersion":"[^"]+' | cut -d'"' -f4)
  NEW=$(echo "$branch" | grep -oE '"newVersion":"[^"]+' | cut -d'"' -f4)
  UPDATE_TYPE=$(echo "$branch" | grep -oE '"updateType":"[^"]+' | cut -d'"' -f4)
  MANAGER=$(echo "$branch" | grep -oE '"manager":"[^"]+' | cut -d'"' -f4)

  if [ -n "$DEP_NAME" ] && [ -n "$CURRENT" ] && [ -n "$NEW" ]; then
    printf -- "- [%s] %s: %s -> %s (%s)\n" "${MANAGER:-unknown}" "$DEP_NAME" "$CURRENT" "$NEW" "${UPDATE_TYPE:-unknown}"
  fi
done

echo ""
echo "Summary: major=$MAJOR_COUNT minor=$MINOR_COUNT patch=$PATCH_COUNT"

exit 1
