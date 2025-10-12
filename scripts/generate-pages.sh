#!/usr/bin/env bash
# Generate HTML files from templates using config/lodge.json
set -euo pipefail

# Ensure UTF-8 encoding for proper character handling
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

LODGE_ROOT="${1:-.}"
CONFIG="$LODGE_ROOT/config/lodge.json"
CORE_DIR="$LODGE_ROOT/core"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: config/lodge.json not found at $CONFIG"
  echo "Please ensure you're running this from the lodge repository root"
  exit 1
fi

if [[ ! -d "$CORE_DIR/templates/pages" ]]; then
  echo "Error: core/templates/pages not found"
  echo "Please ensure the lodge-flipbook-core submodule is initialized"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  echo ""
  echo "Install jq:"
  echo "  Ubuntu/Debian: sudo apt-get install jq"
  echo "  macOS: brew install jq"
  echo "  Windows: choco install jq or scoop install jq"
  exit 1
fi

echo "=========================================="
echo "Generating Pages from Templates"
echo "=========================================="
echo ""

# Extract values from config
LODGE_FULL_NAME=$(jq -r '.titles.siteTitle // .lodge.name' "$CONFIG")
LODGE_SHORT_NAME=$(jq -r '.lodge.shortName // "L" + (.lodge.number // "0000")' "$CONFIG")
LOGO_PATH=$(jq -r '.branding.logo // "/assets/logo.png"' "$CONFIG")
SUMMONS_PREFIX=$(jq -r '.files.summonsPrefix // "Summons"' "$CONFIG")
MINUTES_PREFIX=$(jq -r '.files.minutesPrefix // "Minutes"' "$CONFIG")

echo "Configuration:"
echo "  Lodge: $LODGE_FULL_NAME"
echo "  Short: $LODGE_SHORT_NAME"
echo "  Logo: $LOGO_PATH"
echo "  Summons Prefix: $SUMMONS_PREFIX"
echo "  Minutes Prefix: $MINUTES_PREFIX"
echo ""

# Function to process a template
process_template() {
  local template_path="$1"
  local output_path="$2"
  
  echo "→ Generating: $output_path"
  
  # Ensure output directory exists
  mkdir -p "$(dirname "$output_path")"
  
  # Replace placeholders
  sed \
    -e "s|{{LODGE_FULL_NAME}}|$LODGE_FULL_NAME|g" \
    -e "s|{{LODGE_SHORT_NAME}}|$LODGE_SHORT_NAME|g" \
    -e "s|{{LOGO_PATH}}|$LOGO_PATH|g" \
    -e "s|{{SUMMONS_PREFIX}}|$SUMMONS_PREFIX|g" \
    -e "s|{{MINUTES_PREFIX}}|$MINUTES_PREFIX|g" \
    "$template_path" > "$output_path"
}

# Generate pages
PAGES_DIR="$CORE_DIR/templates/pages"

if [[ -f "$PAGES_DIR/current/index.html.template" ]]; then
  process_template "$PAGES_DIR/current/index.html.template" "$LODGE_ROOT/current/index.html"
fi

if [[ -f "$PAGES_DIR/guides/index.html.template" ]]; then
  process_template "$PAGES_DIR/guides/index.html.template" "$LODGE_ROOT/guides/index.html"
fi

if [[ -f "$PAGES_DIR/meetings/index.html.template" ]]; then
  process_template "$PAGES_DIR/meetings/index.html.template" "$LODGE_ROOT/meetings/index.html"
fi

if [[ -f "$PAGES_DIR/publications/index.html.template" ]]; then
  process_template "$PAGES_DIR/publications/index.html.template" "$LODGE_ROOT/publications/index.html"
fi

if [[ -f "$PAGES_DIR/other/index.html.template" ]]; then
  process_template "$PAGES_DIR/other/index.html.template" "$LODGE_ROOT/other/index.html"
fi

# Generate root index.html from template if it exists
if [[ -f "$CORE_DIR/templates/index.html.template" ]]; then
  echo "→ Generating: index.html"
  sed \
    -e "s|{{LODGE_FULL_NAME}}|$LODGE_FULL_NAME|g" \
    -e "s|{{LODGE_SHORT_NAME}}|$LODGE_SHORT_NAME|g" \
    -e "s|{{LOGO_PATH}}|$LOGO_PATH|g" \
    "$CORE_DIR/templates/index.html.template" > "$LODGE_ROOT/index.html"
fi

# Generate viewer.html from template if it exists
if [[ -f "$CORE_DIR/templates/viewer.html.template" ]]; then
  echo "→ Generating: viewer.html"
  sed \
    -e "s|{{LODGE_FULL_NAME}}|$LODGE_FULL_NAME|g" \
    -e "s|{{LODGE_SHORT_NAME}}|$LODGE_SHORT_NAME|g" \
    -e "s|{{LOGO_PATH}}|$LOGO_PATH|g" \
    "$CORE_DIR/templates/viewer.html.template" > "$LODGE_ROOT/viewer.html"
fi

echo ""
echo "✅ Generated all pages from templates"
echo ""
echo "Pages generated:"
echo "  • index.html"
echo "  • current/index.html"
echo "  • guides/index.html"
echo "  • meetings/index.html"
echo "  • publications/index.html"
echo "  • other/index.html"
echo "  • viewer.html"
echo ""
echo "These files are now customized for: $LODGE_FULL_NAME"
echo ""
echo "To regenerate after template updates:"
echo "  bash core/scripts/generate-pages.sh"
