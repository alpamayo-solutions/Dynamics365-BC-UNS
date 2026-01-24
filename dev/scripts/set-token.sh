#!/bin/bash
# Set OAuth token for Business Central API as environment variable
# Usage: source ./scripts/set-token.sh
#        (must be sourced, not executed, to set the variable in your shell)

ACCESS_TOKEN=$(az account get-access-token \
  --resource https://api.businesscentral.dynamics.com \
  --query accessToken \
  --output tsv 2>/dev/null)

if [ -n "$ACCESS_TOKEN" ]; then
  export ACCESS_TOKEN
  echo "ACCESS_TOKEN set successfully" >&2
else
  echo "Failed to get access token. Run 'az login' first." >&2
  return 1 2>/dev/null || exit 1
fi
