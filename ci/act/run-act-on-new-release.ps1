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

$SecretFile = Join-Path $PSScriptRoot "..\..\.LOCAL\.secrets"
$EventFile = Join-Path $PSScriptRoot "..\..\ci\act\on-new-release-event.json"
$Workflow = Join-Path $PSScriptRoot "..\..\.github\workflows\on-new-release.yml"

Write-Output "🚀 Running act..."

# Note: $PassThruArgs is passed at the end
& act release -P windows-latest=-self-hosted `
    --secret-file "$SecretFile" `
    -e "$EventFile" `
    -W "$Workflow" `
    @PassThruArgs