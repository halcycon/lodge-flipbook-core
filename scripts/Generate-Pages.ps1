# Generate-Pages.ps1
# PowerShell version of generate-pages.sh for Windows environments
param(
    [string]$LodgeRoot = "."
)

$ErrorActionPreference = "Stop"

$ConfigPath = Join-Path $LodgeRoot "config\lodge.json"
$CoreDir = Join-Path $LodgeRoot "_submodules\lodge-flipbook-core"

if (-not (Test-Path $ConfigPath)) {
    $CoreDir = Join-Path $LodgeRoot "core"
    if (-not (Test-Path $CoreDir)) {
        Write-Error "Error: Neither _submodules\lodge-flipbook-core nor core found"
        exit 1
    }
}

if (-not (Test-Path $ConfigPath)) {
    Write-Error "Error: config\lodge.json not found at $ConfigPath"
    exit 1
}

$TemplatesDir = Join-Path $CoreDir "templates\pages"
if (-not (Test-Path $TemplatesDir)) {
    Write-Error "Error: templates\pages not found in core directory"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Generating Pages from Templates" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Read config
$config = Get-Content $ConfigPath | ConvertFrom-Json

$LODGE_FULL_NAME = if ($config.titles.siteTitle) { $config.titles.siteTitle } elseif ($config.branding.siteTitle) { $config.branding.siteTitle } else { $config.lodge.name }
$LODGE_SHORT_NAME = if ($config.lodge.shortName) { $config.lodge.shortName } else { "L$($config.lodge.number)" }
$LOGO_PATH = if ($config.branding.logo) { $config.branding.logo } else { "/assets/logo.png" }
$SUMMONS_PREFIX = if ($config.files.summonsPrefix) { $config.files.summonsPrefix } else { "Summons" }

Write-Host "Configuration:"
Write-Host "  Lodge: $LODGE_FULL_NAME"
Write-Host "  Short: $LODGE_SHORT_NAME"
Write-Host "  Logo: $LOGO_PATH"
Write-Host "  Prefix: $SUMMONS_PREFIX"
Write-Host ""

function Process-Template {
    param(
        [string]$TemplatePath,
        [string]$OutputPath
    )
    
    Write-Host "→ Generating: $OutputPath"
    
    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    Get-Content $TemplatePath | ForEach-Object {
        $_ -replace '\{\{LODGE_FULL_NAME\}\}', $LODGE_FULL_NAME `
           -replace '\{\{LODGE_SHORT_NAME\}\}', $LODGE_SHORT_NAME `
           -replace '\{\{LOGO_PATH\}\}', $LOGO_PATH `
           -replace '\{\{SUMMONS_PREFIX\}\}', $SUMMONS_PREFIX
    } | Set-Content -Path $OutputPath -Encoding UTF8
}

# Generate pages
$pages = @(
    @{template="current\index.html.template"; output="current\index.html"},
    @{template="guides\index.html.template"; output="guides\index.html"},
    @{template="meetings\index.html.template"; output="meetings\index.html"},
    @{template="publications\index.html.template"; output="publications\index.html"},
    @{template="other\index.html.template"; output="other\index.html"}
)

foreach ($page in $pages) {
    $templatePath = Join-Path $TemplatesDir $page.template
    if (Test-Path $templatePath) {
        $outputPath = Join-Path $LodgeRoot $page.output
        Process-Template -TemplatePath $templatePath -OutputPath $outputPath
    }
}

# Generate viewer.html
$viewerTemplate = Join-Path $CoreDir "templates\viewer.html.template"
if (Test-Path $viewerTemplate) {
    Write-Host "→ Generating: viewer.html"
    $viewerOutput = Join-Path $LodgeRoot "viewer.html"
    Process-Template -TemplatePath $viewerTemplate -OutputPath $viewerOutput
}

Write-Host ""
Write-Host "✅ Generated all pages from templates" -ForegroundColor Green
Write-Host ""
Write-Host "Pages generated:"
Write-Host "  • current/index.html"
Write-Host "  • guides/index.html"
Write-Host "  • meetings/index.html"
Write-Host "  • publications/index.html"
Write-Host "  • other/index.html"
Write-Host "  • viewer.html"
Write-Host ""
Write-Host "These files are now customized for: $LODGE_FULL_NAME"
