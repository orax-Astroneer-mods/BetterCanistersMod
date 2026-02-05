param(
    [string]$RepoOwner,
    [string]$RepoName
)

$ResourcesDir = "resources"
$TempDir = ".TEMP"
$TagsPath = Join-Path $TempDir "tags.json"
$IndexPath = Join-Path $ResourcesDir "index.json"
$ModName = $RepoName -replace 'Mod$', ''

# Check if the local file exists
if (-not (Test-Path $TagsPath)) {
    Write-Host "$TagsPath not found. Downloading from GitHub..."

    $TagsUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/tags"
    $Headers = @{ "User-Agent" = "Mozilla/5.0" }  # GitHub API requires a User-Agent

    try {
        # Download tags from GitHub
        $Tags = Invoke-RestMethod -Uri $TagsUrl -Headers $Headers

        # Save locally as JSON
        $Tags | ConvertTo-Json -Depth 10 | Set-Content $TagsPath -Encoding UTF8

        Write-Host "Tags saved to $TagsPath"
    }
    catch {
        throw "Failed to download tags: $_"
    }
}
else {
    Write-Host "$TagsPath already exists. Using local file."
    $Tags = Get-Content $TagsPath -Raw | ConvertFrom-Json
}

# Initialize main structure
$Json = [ordered]@{ mods = [ordered]@{} }
if (Test-Path $IndexPath) {
    # Load existing manifest as a Hashtable to allow dynamic key manipulation
    $Json = Get-Content $IndexPath -Raw | ConvertFrom-Json -AsHashtable
}

# Ensure the specific mod entry exists
if (-not $Json.mods.Contains($ModName)) {
    $Json.mods[$ModName] = [ordered]@{ latest_version = ""; versions = [ordered]@{} }
}

# Process Tags
foreach ($TagObj in $Tags) {
    $TagName = $TagObj.name
    
    # Regex check for semantic versioning (vX.Y.Z)
    if ($TagName -notmatch '^v(\d+\.\d+\.\d+)$') { continue }
    $Version = $Matches[1]

    # Skip if version already exists to save network requests
    if ($Json.mods.$ModName.versions.Contains($Version)) { continue }

    $FileName = "000-$RepoName-$Version`_P"
    $ReleaseUrl = "https://github.com/$RepoOwner/$RepoName/releases/download/$TagName/$FileName"

    try {
        # Verify if the release asset actually exists
        Invoke-WebRequest -Uri $ReleaseUrl -Method Head -UserAgent "Mozilla/5.0" -ErrorAction Stop | Out-Null
        
        $Json.mods.$ModName.versions.$Version = [ordered]@{
            download_url = $ReleaseUrl
            filename     = $FileName
        }
        Write-Host "✅ Added: $Version" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Asset not found for $TagName" -ForegroundColor Red
    }
}

# --- RESTRUCTURING & FINAL SORTING ---

# A. Sort versions for the current mod (using [version] type for correct numerical sorting)
$AllVersions = $Json.mods.$ModName.versions.Keys | Sort-Object { [version]$_ }

if ($AllVersions) {
    $SortedVersions = [ordered]@{}
    foreach ($v in $AllVersions) { 
        $SortedVersions[$v] = $Json.mods.$ModName.versions.$v 
    }

    # Update current mod data
    $Json.mods.$ModName.versions = $SortedVersions
    $Json.mods.$ModName.latest_version = $AllVersions[-1]
}

# B. ALPHABETICAL SORTING OF MODS + KEY ORDERING
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

# Save to File
# Depth 10 ensures nested objects are not truncated
$Json | ConvertTo-Json -Depth 10 | Set-Content $IndexPath
Write-Host "`n✨ File $IndexPath updated and sorted successfully!" -ForegroundColor Cyan
