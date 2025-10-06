# Lodge Flipbook Core

Shared Cloudflare Worker, build scripts, and frontend components.

## What's Here

- `_worker.js.template` - Worker with placeholders for lodge-specific values
- `viewer.html` - PDF flip-book viewer
- `build.sh` - Gallery generation script
- `assets/header.js` - Frontend header/navigation component
- `vendor/` - Third-party libraries (pdf.js, page-flip)
- `scripts/configure.sh` - Template processor

## What's NOT Here

❌ Lodge-specific data (CSV files, agendas)
❌ Build artifacts (*.aux, *.log, *.pdf)
❌ Generated PDFs

Those belong in individual lodge repositories.

## Usage

This repo is designed to be used as a Git submodule in lodge repositories:

```bash
# In lodge repository
git submodule add https://github.com/yourorg/lodge-flipbook-core.git core
git submodule update --init

# Generate _worker.js from template
bash core/scripts/configure.sh
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
