[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassThruArgs
)

# Verify act is installed
if (-not (Get-Command act -ErrorAction SilentlyContinue)) {
    Write-Error "act is not installed. Visit https://nektosact.com/"
    exit 1
}

$SecretFile = Join-Path $PSScriptRoot "..\.LOCAL\.secrets"
$EventFile = Join-Path $PSScriptRoot "..\ci\event.json"

Write-Host "🚀 Running act..." -ForegroundColor Cyan

# Note: $PassThruArgs is passed at the end
& act -P windows-latest=-self-hosted `
    --secret-file "$SecretFile" `
    -e "$EventFile" `
    @PassThruArgs