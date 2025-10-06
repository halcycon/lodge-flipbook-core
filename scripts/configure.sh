#!/usr/bin/env bash
set -euo pipefail

CONFIG="config/lodge.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: config/lodge.json not found"
  echo "Please create it with lodge-specific configuration"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  echo ""
  echo "Install jq:"
  echo "  Ubuntu/Debian: sudo apt-get install jq"
  echo "  macOS: brew install jq"
  echo "  Windows: choco install jq"
  exit 1
fi

echo "Generating _worker.js from template..."

# Extract values from config
LODGE_NUMBER=$(jq -r '.lodge.number' "$CONFIG")
LODGE_DOMAIN=$(jq -r '.branding.domain' "$CONFIG")
SUMMONS_PREFIX=$(jq -r '.files.summonsPrefix' "$CONFIG")
SUMMONS_PATTERN=$(jq -r '.files.summonsPattern' "$CONFIG")
LOGOUT_TITLE=$(jq -r '.titles.logoutTitle' "$CONFIG")
LOGO_PATH=$(jq -r '.branding.logo' "$CONFIG")
LODGE_FULL_NAME=$(jq -r '.titles.siteTitle' "$CONFIG")

# Replace placeholders in template
sed \
  -e "s|{{LODGE_NUMBER}}|$LODGE_NUMBER|g" \
  -e "s|{{LODGE_DOMAIN}}|$LODGE_DOMAIN|g" \
  -e "s|{{SUMMONS_PREFIX}}|$SUMMONS_PREFIX|g" \
  -e "s|{{SUMMONS_PATTERN}}|$SUMMONS_PATTERN|g" \
  -e "s|{{LOGOUT_TITLE}}|$LOGOUT_TITLE|g" \
  -e "s|{{LOGO_PATH}}|$LOGO_PATH|g" \
  -e "s|{{LODGE_FULL_NAME}}|$LODGE_FULL_NAME|g" \
  core/_worker.js.template > _worker.js

echo "✓ Generated _worker.js from template"
echo ""
echo "Configuration used:"
echo "  Lodge: $LODGE_FULL_NAME"
echo "  Number: $LODGE_NUMBER"
echo "  Domain: $LODGE_DOMAIN"
