#!/bin/bash
# List available companies in the Business Central environment
# Usage: ./scripts/list-companies.sh
#
# Requires: ACCESS_TOKEN, BC_TENANT, BC_ENV environment variables
# Run: source ./scripts/set-token.sh  (to set ACCESS_TOKEN)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if it exists (handle comments properly)
if [ -f "$PROJECT_DIR/.env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Remove inline comments and export
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"  # trim trailing whitespace
    [ -n "$line" ] && export "$line"
  done < "$PROJECT_DIR/.env"
fi

# Validate required variables
if [ -z "$BC_TENANT" ] || [ -z "$BC_ENV" ]; then
  echo "Error: Missing required environment variables" >&2
  echo "Set BC_TENANT and BC_ENV in .env or environment" >&2
  exit 1
fi

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: ACCESS_TOKEN not set" >&2
  echo "Run: source ./scripts/set-token.sh" >&2
  exit 1
fi

API_URL="https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/v2.0/companies"

echo "Fetching companies from: $API_URL" >&2
echo "" >&2

curl -s "$API_URL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  | python3 -m json.tool 2>/dev/null || cat
