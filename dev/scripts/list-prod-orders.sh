#!/bin/bash
# List released production orders in Business Central
# Usage: ./scripts/list-prod-orders.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] && export "$line"
  done < "$PROJECT_DIR/.env"
fi

if [ -z "$BC_TENANT" ] || [ -z "$BC_ENV" ] || [ -z "$BC_COMPANY" ]; then
  echo "Error: Missing required environment variables" >&2
  exit 1
fi

# Get token
if [ -z "$ACCESS_TOKEN" ]; then
  ACCESS_TOKEN=$(az account get-access-token \
    --resource https://api.businesscentral.dynamics.com \
    --query accessToken \
    --output tsv 2>/dev/null)
fi

API_URL="https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/v2.0/companies(${BC_COMPANY})/productionOrders?\$filter=status eq 'Released'&\$select=number,description,status&\$top=10"

echo "Fetching released production orders..." >&2
echo "" >&2

curl -s "$API_URL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
orders = data.get('value', [])
if not orders:
    print('No released production orders found.')
else:
    print(f'Found {len(orders)} released production order(s):')
    print()
    for o in orders:
        print(f\"  {o.get('number', 'N/A'):15} - {o.get('description', 'N/A')}\")
" 2>/dev/null || cat
