[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [bool]$IsDraft = $false
)

Set-StrictMode -Version Latest

Write-Host "📝 Release is draft: $IsDraft"

# Default to false if $env:ACT is not set
if ($null -ne $env:ACT) {
    try {
        $act = [bool]::Parse($env:ACT.ToLower())
    }
    catch {
        Write-Warning "Invalid value for ACT: '$($env:ACT)'. Defaulting to false."
        $act = $false
    }
}
else {
    $act = $false
}

Write-Host "🧪 act is $act"


# Check if the local file exists
if (-not (Test-Path $env:TAGS_PATH)) {
    Write-Host "$env:TAGS_PATH not found. Downloading from GitHub..."

    $TagsUrl = "https://api.github.com/repos/$env:REPO_OWNER/$env:REPO_NAME/tags"
    $Headers = @{ "User-Agent" = "Mozilla/5.0" }  # GitHub API requires a User-Agent

    try {
        # Download tags from GitHub
        $Tags = Invoke-RestMethod -Uri $TagsUrl -Headers $Headers

        # Check if $Tags is empty
        if (-not $Tags -or $Tags.Count -eq 0) {
            Write-Warning "❌ No tags were returned from GitHub. URL: $TagsUrl"
            exit
        }

        # Save locally as JSON
        $Tags | ConvertTo-Json -Depth 10 | Set-Content $env:TAGS_PATH -Encoding UTF8

        Write-Host "Tags saved to $env:TAGS_PATH"
    }
    catch {
        throw "Failed to download tags. URL: $TagsUrl $_"
    }
}
else {
    Write-Host "$env:TAGS_PATH already exists. Using local file."
    $Tags = Get-Content $env:TAGS_PATH -Raw | ConvertFrom-Json
}

# Initialize main structure
$Json = [ordered]@{ mods = [ordered]@{} }
if (Test-Path $env:INDEX_PATH) {
    # Load existing manifest as a Hashtable to allow dynamic key manipulation
    $Json = Get-Content $env:INDEX_PATH -Raw | ConvertFrom-Json -AsHashtable
}

# Ensure the specific mod entry exists
if (-not $Json.mods.Contains($env:CANONICAL_MOD_NAME)) {
    $Json.mods[$env:CANONICAL_MOD_NAME] = [ordered]@{ latest_version = ""; versions = [ordered]@{} }
}

# Process Tags
foreach ($TagObj in $Tags) {
    $TagName = $TagObj.name
    
    # Regex check for semantic versioning (vX.Y.Z)
    if ($TagName -notmatch '^v(\d+\.\d+\.\d+)$') { continue }
    $Version = $Matches[1]

    # Skip if version already exists to save network requests
    if ($Json.mods.$env:CANONICAL_MOD_NAME.versions.Contains($Version)) { continue }

    $FileName = "000-$env:REPO_NAME-$Version`_P.pak"
    $ReleaseUrl = "https://github.com/$env:REPO_OWNER/$env:REPO_NAME/releases/download/$TagName/$FileName"

    try {
        # Verify if the release asset actually exists
        Invoke-WebRequest -Uri $ReleaseUrl -Method Head -UserAgent "Mozilla/5.0" -ErrorAction Stop | Out-Null
        
        $Json.mods.$env:CANONICAL_MOD_NAME.versions.$Version = [ordered]@{
            download_url = $ReleaseUrl
            filename     = $FileName
        }
        Write-Host "✅ Added: $Version" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Asset not found for $TagName. URL: $ReleaseUrl" -ForegroundColor Red
    }
}

# --- RESTRUCTURING & FINAL SORTING ---

# Sort versions for the current mod (using [version] type for correct numerical sorting)
$AllVersions = $Json.mods.$env:CANONICAL_MOD_NAME.versions.Keys | Sort-Object { [version]$_ }

if ($AllVersions) {
    $SortedVersions = [ordered]@{}
    foreach ($v in $AllVersions) { 
        $SortedVersions[$v] = $Json.mods.$env:CANONICAL_MOD_NAME.versions.$v
    }

    # Update current mod data
    $Json.mods.$env:CANONICAL_MOD_NAME.versions = $SortedVersions
    $Json.mods.$env:CANONICAL_MOD_NAME.latest_version = $AllVersions | Select-Object -Last 1
}

# ALPHABETICAL SORTING OF MODS + KEY ORDERING
$SortedMods = [ordered]@{}
$ModNames = $Json.mods.Keys | Sort-Object # Alphabetical sort of mod names

foreach ($Name in $ModNames) {
    $CurrentMod = $Json.mods[$Name]
    
    # Reconstruct the mod object to force 'latest_version' to appear BEFORE 'versions'
    $SortedMods[$Name] = [ordered]@{
        latest_version = $CurrentMod.latest_version
        versions       = $CurrentMod.versions
    }
}

# Replace the unsorted mods list with the sorted one
$Json.mods = $SortedMods

# Convert your object to JSON (Depth 10 to preserve nested objects)
$JsonText = $Json | ConvertTo-Json -Depth 10

# ANSI escape codes for colors (works in act)
$Cyan = "`e[36;41m"
$Reset = "`e[0m"

$Output = "✅ test"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output $Output


# Print title in cyan
Write-Host "${Cyan}📄 Current JSON content:${Reset}`n"

# Print JSON as plain text
Write-Output $JsonText

# Save JSON to file
$JsonText | Set-Content $env:INDEX_PATH -Encoding UTF8

Write-Host "`n✨ File $env:INDEX_PATH updated and sorted successfully!`n"
