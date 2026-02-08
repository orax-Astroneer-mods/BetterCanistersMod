#
# Create "AstroModLoader Classic" PAK archive
#

$astroneer_pakDirName = "000-$repoName-${version}_P"
$astroneer_pakFileName = "$astroneer_pakDirName.pak"
$astroneer_pakDir = Join-Path $env:RELEASE_DIR $astroneer_pakDirName
$astroneer_resourcesDir = Join-Path $PSScriptRoot "../" $env:RESOURCES_DIR

# Create the directory for AstroModLoader Classic
if (Test-Path $astroneer_pakDir) {
    Remove-Item -Path $astroneer_pakDir -Recurse -Force
}
New-Item -Path $astroneer_pakDir -ItemType Directory | Out-Null

# Create the UE4SS directory
$UE4SSDir = Join-Path $astroneer_pakDir "UE4SS"
New-Item -Path $UE4SSDir -ItemType Directory | Out-Null

# Move existing TargetDir into UE4SS
Move-Item -Path $env:TARGET_DIR -Destination $UE4SSDir

#
# Write metadata.json
#

$metadataFile = "metadata.json"
$SourceMetadata = Join-Path $astroneer_resourcesDir $metadataFile
$TargetMetadata = Join-Path $astroneer_pakDir $metadataFile

# Read file content
$Content = Get-Content $SourceMetadata -Raw

# Replace placeholders
$Content = $Content -replace '\{VERSION\}', $env:VERSION
$Content = $Content -replace '\{MOD_ID\}', $env:REPO_NAME
$Content = $Content -replace '\{MOD_NAME\}', $env:MOD_NAME
$Content = $Content -replace '\{MOD_DESCRIPTION\}', $env:MOD_DESCRIPTION

Set-Content -Path $TargetMetadata -Value $Content -Encoding utf8

#
# Create the PAK file
# https://astroneermodding.readthedocs.io/en/latest/guides/basicSetup.html#setting-up-repak
# https://github.com/trumank/repak
#

$RepakExe = Join-Path $env:PROJECT_ROOT_DIR "$env:RESOURCES_DIR/repak_cli-x86_64-pc-windows-msvc/repak.exe"

if (-not (Test-Path $astroneer_pakDir)) {
    throw "PAK directory does not exist: $astroneer_pakDir"
}

$CmdArgs = @("pack", "--version", "V4", $astroneer_pakDir)
Write-Output "Run command: $RepakExe $($CmdArgs -join ' ')"
& $RepakExe @CmdArgs

$FullPakPath = Join-Path $env:RELEASE_DIR $astroneer_pakFileName

if ($LASTEXITCODE -ne 0) {
    throw "PAK build failed: $RepakExe returned exit code $LASTEXITCODE."
}

if (-not (Test-Path $FullPakPath)) {
    throw "PAK build failed: File not found at expected location -> $FullPakPath"
}