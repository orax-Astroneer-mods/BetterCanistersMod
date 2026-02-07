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

Set-StrictMode -Version Latest

#
# Prepare the release folder
#

if (-Not (Test-Path $env:RELEASE_DIR)) {
    New-Item -Path $env:RELEASE_DIR -ItemType Directory | Out-Null
}

if (Test-Path $env:TARGET_DIR) {
    Remove-Item -Path $env:TARGET_DIR -Recurse -Force
}

New-Item -Path $env:TARGET_DIR -ItemType Directory | Out-Null

#
# Copy files
#

# Read excluded files for the release from an external file
$Excludes = Get-Content -Path '.\ci\excluded-files-in-release.txt'

# Copy "Scripts" directory
Copy-Item -Path 'Scripts' -Destination $env:TARGET_DIR -Recurse

# Copy all files in the current directory except the excluded ones
Get-ChildItem -File | Where-Object { $Excludes -notcontains $_.Name } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $env:TARGET_DIR
}

#
# Create enabled.txt and version.txt
#

New-Item -Path (Join-Path $env:TARGET_DIR "enabled.txt") -ItemType File | Out-Null
Set-Content -Path (Join-Path $env:TARGET_DIR "version.txt") -Value $env:VERSION

#
# Create ZIP archive
#

if (Test-Path $env:RELEASE_FULL_PATH) { Remove-Item $env:RELEASE_FULL_PATH }

Compress-Archive -Path $env:TARGET_DIR -DestinationPath $env:RELEASE_FULL_PATH -Force
Write-Output "ZIP created: $env:RELEASE_FULL_PATH"

if (-not (Test-Path $env:RELEASE_FULL_PATH)) {
    throw "ZIP release failed."
}

#
# Create "AstroModLoader Classic" archive
#

# Create the directory for AstroModLoader Classic
if (Test-Path $env:PAK_TARGET_DIR) {
    Remove-Item -Path $env:PAK_TARGET_DIR -Recurse -Force
}
New-Item -Path $env:PAK_TARGET_DIR -ItemType Directory | Out-Null

# Create the UE4SS directory
$UE4SSDir = Join-Path $env:PAK_TARGET_DIR "UE4SS"
New-Item -Path $UE4SSDir -ItemType Directory | Out-Null

# Move existing TargetDir into UE4SS
Move-Item -Path $env:TARGET_DIR -Destination $UE4SSDir

#
# Write metadata.json
#

$metadataFile = "metadata.json"
$SourceMetadata = "$env:RESOURCES_DIR\$metadataFile"
$TargetMetadata = Join-Path $env:PAK_TARGET_DIR $metadataFile

# Read file content
$Content = Get-Content $SourceMetadata

$Content = $Content -replace '{VERSION}', $env:VERSION
$Content = $Content -replace '{MOD_ID}', $env:REPO_NAME
$Content = $Content -replace '{MOD_NAME}', $env:MOD_NAME
$Content = $Content -replace '{MOD_DESCRIPTION}', $env:MOD_DESCRIPTION

# Write modified file
Set-Content -Path $TargetMetadata -Value $Content -Encoding UTF8

#
# Create the PAK file
# https://astroneermodding.readthedocs.io/en/latest/guides/basicSetup.html#setting-up-repak
# https://github.com/trumank/repak
#

$RepakExe = Join-Path $env:RESOURCES_DIR "repak_cli-x86_64-pc-windows-msvc\repak.exe"
$PakDir = (Resolve-Path $env:PAK_TARGET_DIR).Path

$CmdArgs = @("pack", "--version", "V4", $PakDir)
Write-Output "Run command: $RepakExe $($CmdArgs -join ' ')"
& $RepakExe @CmdArgs

if ($LASTEXITCODE -ne 0 -or -not (Test-Path "$env:PAK_RELEASE_FULL_PATH")) {
    throw "PAK build failed."
}
