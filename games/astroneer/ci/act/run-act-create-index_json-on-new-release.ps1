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

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "../../../../")).Path
$SecretFile = Join-Path $RootDir "/.LOCAL/.secrets"
$EventFile = Join-Path $RootDir "/games/astroneer/ci/act/create-index_json-on-new-release-event.json"
$Workflow = Join-Path $RootDir "/.github/workflows/games/astroneer/create-index_json-on-new-release.yml"

Write-Output "🚀 Running act..."

# Note: $PassThruArgs is passed at the end
& act release -P windows-latest=-self-hosted `
    --secret-file "$SecretFile" `
    -e "$EventFile" `
    -W "$Workflow" `
    @PassThruArgs