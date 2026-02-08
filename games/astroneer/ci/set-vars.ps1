Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($releaseDir) -or
    [string]::IsNullOrWhiteSpace($repoName ) -or
    [string]::IsNullOrWhiteSpace($version ) -or
    [string]::IsNullOrWhiteSpace($tempDir )) {
    throw "❌ Required variables are missing!"
}

$astroneer_games_dir = "games\astroneer"
$astroneer_resourcesDir = Join-Path $astroneer_games_dir "resources"
$astroneer_pakTargetDir = Join-Path $releaseDir "000-$repoName-$version`_P"

$astroneer_tagsPath = Join-Path $tempDir "tags.json"
$astroneer_indexPath = Join-Path $astroneer_resourcesDir "index.json"

$astroneer_pakReleaseFilename = "000-$repoName-$version`_P.pak"
$astroneer_pakReleaseRelPath = Join-Path $releaseDir $astroneer_pakReleaseFilename

@{
    ASTRONEER_GAMES_DIR            = $astroneer_games_dir
    ASTRONEER_RESOURCES_DIR        = $astroneer_resourcesDir

    ASTRONEER_PAK_TARGET_DIR       = $astroneer_pakTargetDir

    ASTRONEER_TAGS_PATH            = $astroneer_tagsPath
    ASTRONEER_INDEX_PATH           = $astroneer_indexPath

    ASTRONEER_PAK_RELEASE_FILENAME = $astroneer_pakReleaseFilename
    ASTRONEER_PAK_RELEASE_REL_PATH = $astroneer_pakReleaseRelPath
}.GetEnumerator() | ForEach-Object {
    if ($env:GITHUB_ENV) {
        # Export for next GitHub Actions steps
        "$($_.Key)=$($_.Value)" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    }
    else {
        # Make variable available in the current script (useful when script is run locally)
        Set-Item -Path "env:$($_.Key)" -Value $_.Value
    }
}

# List of directories to create
$dirs = @($astroneer_resourcesDir)

# Create each directory if it doesn't exist
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory | Out-Null
    }
}
