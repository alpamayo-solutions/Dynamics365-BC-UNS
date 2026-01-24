#!/bin/bash
# Test the Execution Events API
# Usage: ./scripts/test-api.sh [order-no] [operation-no] [message-id]
#
# Requires: BC_TENANT, BC_ENV, BC_COMPANY environment variables in .env

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if it exists (handle comments properly)
if [ -f "$PROJECT_DIR/.env" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] && export "$line"
  done < "$PROJECT_DIR/.env"
fi

# Validate required variables
if [ -z "$BC_TENANT" ] || [ -z "$BC_ENV" ] || [ -z "$BC_COMPANY" ]; then
  echo "Error: Missing required environment variables" >&2
  echo "Set BC_TENANT, BC_ENV, and BC_COMPANY in .env or environment" >&2
  exit 1
fi

# Function to get/refresh token
get_token() {
  ACCESS_TOKEN=$(az account get-access-token \
    --resource https://api.businesscentral.dynamics.com \
    --query accessToken \
    --output tsv 2>/dev/null)

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to get access token. Run 'az login' first." >&2
    exit 1
  fi
}

# Function to send request
send_request() {
  curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X POST "$API_URL" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"messageId\": \"$MESSAGE_ID\",
      \"orderNo\": \"$ORDER_NO\",
      \"operationNo\": \"$OPERATION_NO\",
      \"workCenter\": \"MACH0001\",
      \"nParts\": 100,
      \"nRejected\": 5,
      \"runtimeSec\": 3600,
      \"downtimeSec\": 300,
      \"availability\": 0.92,
      \"productivity\": 0.85,
      \"actualCycleTimeSec\": 36.5,
      \"sourceTimestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
      \"source\": \"TEST-SCRIPT\"
    }"
}

# Get token if not set
if [ -z "$ACCESS_TOKEN" ]; then
  echo "Getting access token..." >&2
  get_token
fi

# Parse arguments
ORDER_NO="${1:-101001}"
OPERATION_NO="${2:-10}"
MESSAGE_ID="${3:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"

# Build API URL
API_URL="https://api.businesscentral.dynamics.com/v2.0/${BC_TENANT}/${BC_ENV}/api/alpamayo/shopfloor/v1.0/companies(${BC_COMPANY})/executionEvents"

echo "Sending request to: $API_URL" >&2
echo "Order No: $ORDER_NO, Operation No: $OPERATION_NO" >&2
echo "Message ID: $MESSAGE_ID" >&2
echo "" >&2

# Send request
RESPONSE=$(send_request)
HTTP_STATUS=$(echo "$RESPONSE" | grep -o 'HTTP_STATUS:[0-9]*' | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

# If unauthorized, refresh token and retry
if [ "$HTTP_STATUS" = "401" ]; then
  echo "Token expired, refreshing..." >&2
  get_token
  RESPONSE=$(send_request)
  HTTP_STATUS=$(echo "$RESPONSE" | grep -o 'HTTP_STATUS:[0-9]*' | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')
fi

echo "$BODY"
echo ""
echo "HTTP Status: $HTTP_STATUS"
