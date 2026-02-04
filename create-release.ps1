<#
.SYNOPSIS
PowerShell script to create a GitHub release
.DESCRIPTION
- Copies files into .RELEASE
- Creates version.txt and enabled.txt files
- Creates a ZIP archive
- Calculates the SHA-256 hash
- (Optional) Depends on softprops/action-gh-release to create the release
#>

param(
    [string]$ReleaseDir = ".RELEASE",
    [string]$HashAlgorithm = "SHA-256",
    [switch]$IsDraft
)

# ------------------------------------------------------ #

# ---------------------------
# GitHub variables
# ---------------------------
$RepoName = Split-Path -Path (Get-Location) -Leaf
$Tag = $env:GITHUB_REF_NAME
if (-not $Tag) { $Tag = "v0.0.0" } # fallback if running locally
$Version = $Tag -replace '^v(?=\d+\.\d+\.\d+)', ''
$ReleaseFilename = "$RepoName.zip"
$TargetDir = Join-Path $ReleaseDir $RepoName

Write-Host "RepoName: $RepoName"
Write-Host "Version: $Version"
Write-Host "ReleaseDir: $ReleaseDir"
Write-Host "TargetDir: $TargetDir"
Write-Host "ReleaseFilename: $ReleaseFilename"

# ---------------------------
# Prepare the release folder
# ---------------------------
if (-Not (Test-Path $ReleaseDir)) {
    New-Item -Path $ReleaseDir -ItemType Directory | Out-Null
}

if (Test-Path $TargetDir) {
    Remove-Item -Path $TargetDir -Recurse -Force
}

New-Item -Path $TargetDir -ItemType Directory | Out-Null

# ---------------------------
# Copy files
# ---------------------------
# Read excluded files for the release from an external file
$Excludes = Get-Content -Path 'excluded-files-in-release.txt'
# Copy "Scripts" directory
Copy-Item -Path 'Scripts' -Destination $TargetDir -Recurse
# Copy all files in the current directory except the excluded ones
Get-ChildItem -File | Where-Object { $Excludes -notcontains $_.Name } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $TargetDir
}

# Create enabled.txt and version.txt
New-Item -Path (Join-Path $TargetDir "enabled.txt") -ItemType File | Out-Null
Set-Content -Path (Join-Path $TargetDir "version.txt") -Value $Version

# ---------------------------
# Create ZIP archive
# ---------------------------
$ZipPath = Join-Path $ReleaseDir $ReleaseFilename
if (Test-Path $ZipPath) { Remove-Item $ZipPath }

Compress-Archive -Path $TargetDir -DestinationPath $ZipPath -Force
Write-Host "ZIP created: $ZipPath"

# ---------------------------
# Calculate the hash
# ---------------------------
$Hash = (Get-FileHash -Algorithm ($HashAlgorithm -replace "-", "") -Path $ZipPath).Hash
Write-Host "SHA-256: $Hash"

# ---------------------------
# Export variables for GitHub Actions
# ---------------------------
if ($env:GITHUB_REF_NAME) {
    "VERSION=$Version" | Out-File -FilePath $env:GITHUB_ENV -Append
    "RELEASE_FILENAME=$ReleaseFilename" | Out-File -FilePath $env:GITHUB_ENV -Append
    "HASH=$Hash" | Out-File -FilePath $env:GITHUB_ENV -Append
}
