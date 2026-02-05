[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$github_ref_name,

    [Parameter(Mandatory)]
    [string]$github_repository
)

Set-StrictMode -Version Latest

$readmeFile = "README.md"
$version = $github_ref_name -replace '^v(?=\d+\.\d+\.\d+)', ''
$repo = $github_repository
$repoOwner, $repoName = $repo -split '/'
$canonicalModName = $repoName -replace 'Mod$', ''

$modName = ""
try {
    $modName = (Get-Content $readmeFile -TotalCount 1) -replace '^#\s+', ''
}
catch {
    throw "Unable to get mod name from $readmeFile."
}

$resourcesDir = "resources"
$tempDir = ".TEMP"
$releaseDir = ".RELEASE"
$targetDir = Join-Path $releaseDir $repoName
$pakTargetDir = Join-Path $releaseDir "000-$repoName-$version`_P"

$tagsPath = Join-Path $tempDir "tags.json"
$indexPath = Join-Path $resourcesDir "index.json"
        
$releaseFilename = "$repoName.zip"
$releaseFullPath = "$releaseDir\$releaseFilename"
$pakReleaseFilename = "000-$repoName-$version`_P.pak"
$pakReleaseFullPath = "$releaseDir\$pakReleaseFilename"
       
$hashAlgorithm = "SHA-256"

# Read description in README.md
# Format:
#    # Mod name
#
#    > Description...
#    > More description...
#
#    Other text.
$lines = Get-Content $readmeFile | Select-Object -Skip 2
$description = ''
foreach ($line in $lines) {
    if ($line -like '>*') {
        # Remove the leading '>' and spaces
        $cleanLine = $line -replace '^> *', ''

        # Add literal \n if descriptionText is not empty (i.e., not first line)
        if ($description -ne '') {
            $description += '\n'
        }

        $description += $cleanLine -replace ' +$', ''
    }
    else {
        break
    }
}

@{
    VERSION               = $version
    REPO_OWNER            = $repoOwner
    REPO_NAME             = $repoName
    CANONICAL_MOD_NAME    = $canonicalModName 
    MOD_NAME              = $modName

    RESOURCES_DIR         = $resourcesDir
    TEMP_DIR              = $tempDir
    RELEASE_DIR           = $releaseDir
    TARGET_DIR            = $targetDir
    PAK_TARGET_DIR        = $pakTargetDir

    TAGS_PATH             = $tagsPath
    INDEX_PATH            = $indexPath

    RELEASE_FILENAME      = $releaseFilename
    RELEASE_FULL_PATH     = $releaseFullPath
    PAK_RELEASE_FILENAME  = $pakReleaseFilename
    PAK_RELEASE_FULL_PATH = $pakReleaseFullPath

    HASH_ALGORITHM        = $hashAlgorithm

    MOD_DESCRIPTION       = $description
}.GetEnumerator() | ForEach-Object {
    if ($env:GITHUB_ENV) {
        # Export for next GitHub Actions steps
        "$($_.Key)=$($_.Value)" | Out-File $env:GITHUB_ENV -Append
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
