# Lodge Flipbook Core

Shared Cloudflare Worker, build scripts, and frontend components for lodge document flipbook sites.

## What's Here

✅ **Templates:**
- `templates/pages/` - HTML page templates (current/, guides/, meetings/, publications/, other/)
- `templates/viewer.html.template` - PDF flip-book viewer template
- `_worker.js.template` - Worker with placeholders for lodge-specific values

✅ **Build Scripts:**
- `scripts/generate-pages.sh` - Generate HTML pages from templates
- `scripts/configure.sh` - Generate _worker.js from template
- `build.sh` - Gallery generation script for PDFs

✅ **Frontend Assets:**
- `assets/header.js` - Dynamic header/navigation component
- `vendor/` - Third-party libraries (pdf.js, page-flip)

## What's NOT Here

❌ Lodge-specific data (CSV files, agendas)
❌ Build artifacts (*.aux, *.log, *.pdf)
❌ Generated PDFs
❌ config/lodge.json (lodge configuration)

Those belong in **individual lodge repositories**.

## Usage

This repo is designed to be used as a Git submodule in lodge repositories.

### Initial Setup

```bash
# In lodge repository
git submodule add https://github.com/yourorg/lodge-flipbook-core.git core
git submodule update --init

# Generate all HTML pages and _worker.js
bash core/scripts/generate-pages.sh
bash core/scripts/configure.sh
```

### After Template Updates

When the core repository is updated with new template features:

```bash
# Update submodule to latest
git submodule update --remote core

# Regenerate pages with new templates
bash core/scripts/generate-pages.sh

# Regenerate worker if needed
bash core/scripts/configure.sh

# Review changes
git diff

# Commit if satisfied
git add .
git commit -m "Update from core templates"
```

## Template System

### Page Templates

Each HTML page uses placeholders that are replaced by `generate-pages.sh`:

| Placeholder | Source | Example |
|-------------|--------|---------|
| `{{LODGE_FULL_NAME}}` | branding.siteTitle or lodge.name | Hundred Elms Lodge No. 5749 |
| `{{LODGE_SHORT_NAME}}` | lodge.shortName or "L" + lodge.number | L5749 |
| `{{LOGO_PATH}}` | branding.logo | /assets/l5749-logo.png |
| `{{SUMMONS_PREFIX}}` | files.summonsPrefix | L5749-Summons- |

### Pages Generated

- `current/index.html` - Current meeting pack page
- `guides/index.html` - Ritual guides index
- `meetings/index.html` - Individual meeting bundle page
- `publications/index.html` - Archive/publications gallery
- `other/index.html` - Other documents page
- `viewer.html` - PDF flip-book viewer

### Worker Template

`_worker.js.template` uses the same placeholders plus:

- `{{LODGE_DOMAIN}}` - branding.domain
- `{{SUMMONS_PATTERN}}` - files.summonsPattern
- `{{LOGOUT_TITLE}}` - titles.logoutTitle

### Customization

**For lodge-wide changes:** Edit templates in this repo, push, update all lodges.

**For lodge-specific changes:** Edit generated files in the lodge repo (won't be overwritten unless you regenerate).

## config/lodge.json Structure

Lodge repositories must have `config/lodge.json`:

```json
{
  "lodge": {
    "name": "Hundred Elms Lodge",
    "number": "5749",
    "shortName": "L5749"
  },
  "branding": {
    "siteTitle": "Hundred Elms Lodge No. 5749",
    "domain": "files.hundredelmslodge.org.uk",
    "logo": "/assets/l5749-logo.png"
  },
  "files": {
    "summonsPrefix": "L5749-Summons-",
    "summonsPattern": "L5749-Summons-\\d{4}\\.pdf"
  },
  "titles": {
    "logoutTitle": "Hundred Elms Lodge No. 5749",
    "siteTitle": "Hundred Elms Lodge No. 5749"
  }
}
```

## Placeholders in _worker.js.template

The following placeholders should be replaced by `scripts/configure.sh`:

- `{{LODGE_NUMBER}}` - Lodge number (e.g., 5749)
- `{{LODGE_DOMAIN}}` - Lodge domain (e.g., files.hundredelmslodge.org.uk)
- `{{SUMMONS_PREFIX}}` - File prefix (e.g., L5749-Summons-)
- `{{SUMMONS_PATTERN}}` - Regex pattern for thumbnails
- `{{LOGOUT_TITLE}}` - Page title for logout page
- `{{LOGO_PATH}}` - Path to lodge logo
- `{{LODGE_FULL_NAME}}` - Full lodge name

## Next Steps

1. Review `_worker.js.template` and replace lodge-specific strings with placeholders
2. Test `scripts/configure.sh` with a sample config/lodge.json
3. Push to GitHub
4. Add as submodule to lodge repositories

## License

[Your License]
