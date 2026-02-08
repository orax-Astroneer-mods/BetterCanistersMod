[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$github_ref_name,

    [Parameter(Mandatory)]
    [string]$github_repository
)

Set-StrictMode -Version Latest

Write-Host "🏷️ github_ref_name: $github_ref_name"
Write-Host "📦 github_repository: $github_repository"

$projectRootDir = (Resolve-Path (Join-Path $PSScriptRoot "../")).Path
$version = $github_ref_name -replace '^v(?=\d+\.\d+\.\d+)', ''
$repoOwner, $repoName = $github_repository -split '/'

$tempDir = ".TEMP"
$releaseDir = ".RELEASE"
$resourcesDir = "resources"
$targetDir = Join-Path $releaseDir $repoName
     
$releaseFilename = "$repoName.zip"
$releaseRelPath = "$releaseDir\$releaseFilename"

# Read the mod metadata in the mod.json file.
$jsonPath = Join-Path $projectRootDir "mod.json"
$jsonRawContent = Get-Content -Path $jsonPath -Raw -Encoding utf8
$schemaPath = "./resources/schema.json"
if (-not ($jsonRawContent | Test-Json)) {
    throw "❌ Malformed JSON (syntax error). JSON path: $jsonPath"
}
if (-not ($jsonRawContent | Test-Json -SchemaFile $schemaPath)) {
    throw "❌ JSON is valid but does not conform to the schema rules. JSON path: $jsonPath"
}
$modMetadata = $jsonRawContent | ConvertFrom-Json

@{
    PROJECT_ROOT_DIR   = $projectRootDir

    VERSION            = $version
    REPO_OWNER         = $repoOwner
    REPO_NAME          = $repoName
    MOD_AUTHOR         = $modMetadata.author
    MOD_CANONICAL_NAME = $modMetadata.canonical_name 
    MOD_DESCRIPTION    = $modMetadata.description
    MOD_HOMEPAGE       = $modMetadata.homepage
    MOD_NAME           = $modMetadata.name

    RESOURCES_DIR      = $resourcesDir
    TEMP_DIR           = $tempDir
    RELEASE_DIR        = $releaseDir
    TARGET_DIR         = $targetDir

    RELEASE_FILENAME   = $releaseFilename
    RELEASE_REL_PATH   = $releaseRelPath
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
$dirs = @($resourcesDir, $tempDir, $releaseDir)

# Create each directory if it doesn't exist
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory | Out-Null
    }
}

# Set variables for a custom game if exists
if ($github_repository -match "-([^-]+)-mods/") {
    $gameName = $Matches[1]
    Write-Output "🕹️ Set environment variables for the game: $gameName"
    $gameName = $gameName.ToLowerInvariant()
    $scriptName = "set-vars.ps1"
    "GAME_NAME=$gameName" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    $scriptPath = Join-Path $projectRootDir "games/$gameName/ci/$scriptName"

    if (Test-Path $scriptPath) {
        Write-Output "🚀 Executing custom script '$scriptName' for this game: $scriptPath"
        # Set game-specific environment variables
        . $scriptPath
    }
    else {
        throw "❌ Custom script for the game '$gameName' does not exist. scriptPath: $scriptPath"
    }
}
