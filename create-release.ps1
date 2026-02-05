<#
.SYNOPSIS
PowerShell script to create a GitHub release
.DESCRIPTION
- Copies files into .RELEASE
- Creates version.txt and enabled.txt files
- Creates a ZIP archive and a PAK file
- Calculates the SHA-256 hash
- (Optional) Depends on softprops/action-gh-release to create the release
#>

param(
    [string]$ReleaseDir = ".RELEASE",
    [string]$HashAlgorithm = "SHA-256",
    [string]$ResourcesDir = "resources"
)

# GitHub variables
#
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

#
# Prepare the release folder
#

if (-Not (Test-Path $ReleaseDir)) {
    New-Item -Path $ReleaseDir -ItemType Directory | Out-Null
}

if (Test-Path $TargetDir) {
    Remove-Item -Path $TargetDir -Recurse -Force
}

New-Item -Path $TargetDir -ItemType Directory | Out-Null

#
# Copy files
#

# Read excluded files for the release from an external file
$Excludes = Get-Content -Path 'excluded-files-in-release.txt'

# Copy "Scripts" directory
Copy-Item -Path 'Scripts' -Destination $TargetDir -Recurse

# Copy all files in the current directory except the excluded ones
Get-ChildItem -File | Where-Object { $Excludes -notcontains $_.Name } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $TargetDir
}

#
# Create enabled.txt and version.txt
#

New-Item -Path (Join-Path $TargetDir "enabled.txt") -ItemType File | Out-Null
Set-Content -Path (Join-Path $TargetDir "version.txt") -Value $Version

#
# Create ZIP archive
#

$ZipPath = Join-Path $ReleaseDir $ReleaseFilename
if (Test-Path $ZipPath) { Remove-Item $ZipPath }

Compress-Archive -Path $TargetDir -DestinationPath $ZipPath -Force
Write-Host "ZIP created: $ZipPath"

if (-not (Test-Path $ZipPath)) {
    throw "ZIP release failed."
}

#
# Calculate the hash
#

$Hash = (Get-FileHash -Algorithm ($HashAlgorithm -replace "-", "") -Path $ZipPath).Hash
Write-Host "SHA-256: $Hash"

#
# Create "AstroModLoader Classic" archive
#

# Create the directory for AstroModLoader Classic
$TargetDirForAML = Join-Path $ReleaseDir "000-$RepoName-$Version`_P"
if (Test-Path $TargetDirForAML) {
    Remove-Item -Path $TargetDirForAML -Recurse -Force
}
New-Item -Path $TargetDirForAML -ItemType Directory | Out-Null

# Create the UE4SS directory
$UE4SSDir = Join-Path $TargetDirForAML "UE4SS"
New-Item -Path $UE4SSDir -ItemType Directory | Out-Null

# Move existing TargetDir into UE4SS
Move-Item -Path $TargetDir -Destination $UE4SSDir
$TargetDir = $null

#
# Write metadata.json
#

$SourceMetadata = "$ResourcesDir\metadata.json"
$TargetMetadata = Join-Path $TargetDirForAML "metadata.json"

# Read file content
$Content = Get-Content $SourceMetadata

$ModNameWithSpaces = $RepoName -replace '([a-z0-9])([A-Z])', '$1 $2' -replace '([A-Z]+)([A-Z][a-z])', '$1 $2'

$Content = $Content -replace '{Version}', $Version
$Content = $Content -replace '{ModId}', $RepoName
$Content = $Content -replace '{ModNameWithSpaces}', $ModNameWithSpaces

# Write modified file
Set-Content -Path $TargetMetadata -Value $Content -Encoding UTF8

#
# Create the PAK file
# https://astroneermodding.readthedocs.io/en/latest/guides/basicSetup.html#setting-up-repak
# https://github.com/trumank/repak
#

& "$ResourcesDir\repak_cli-x86_64-pc-windows-msvc\repak.exe" pack --version V4 --compression Zlib (Resolve-Path $TargetDirForAML).Path

# Expected pak file
$ReleasePakFilename = "$TargetDirForAML.pak"

if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ReleasePakFilename)) {
    throw "PAK build failed."
}

#
# Calculate the hash of the PAK file
#

$HashPakFile = (Get-FileHash -Algorithm ($HashAlgorithm -replace "-", "") -Path $ReleasePakFilename).Hash
Write-Host "SHA-256: $HashPakFile"

#
# Export variables for GitHub Actions
#

return @{
    VERSION              = $Version
    RELEASE_FILENAME     = $ReleaseFilename
    RELEASE_PAK_FILENAME = $ReleasePakFilename
    HASH                 = $Hash
    HASH_PAK_FILE        = $HashPakFile
}
