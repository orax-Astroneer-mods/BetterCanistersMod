$releaseFile = "$env:RELEASE_DIR\$env:RELEASE_FILENAME"
$pakReleaseFile = "$env:RELEASE_DIR\$env:PAK_RELEASE_FILENAME"

if (-not (Test-Path $releaseFile)) {
    throw "Release file not found: $releaseFile"
}

if (-not (Test-Path $pakReleaseFile)) {
    throw "PAK release file not found: $pakReleaseFile"
}

# -----------------------
# Hash ZIP
# -----------------------

$hash = (Get-FileHash `
        -Algorithm ($env:HASH_ALGORITHM -replace "-", "") `
        -Path $releaseFile
).Hash

Write-Host "releaseFile => $($env:HASH_ALGORITHM): $hash"

if ($env:GITHUB_ENV) {
    "HASH=$hash" | Out-File -FilePath $env:GITHUB_ENV -Append
}

# -----------------------
# Hash PAK
# -----------------------

$hashPakFile = (Get-FileHash `
        -Algorithm ($env:HASH_ALGORITHM -replace "-", "") `
        -Path $pakReleaseFile
).Hash

Write-Host "pakReleaseFile => $($env:HASH_ALGORITHM): $hashPakFile"

if ($env:GITHUB_ENV) {
    "HASH_PAK_FILE=$hashPakFile" | Out-File -FilePath $env:GITHUB_ENV -Append
}
