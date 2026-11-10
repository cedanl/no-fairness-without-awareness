$Script:ManifestPath = "$env:USERPROFILE\.cedanl-devsetup\state.json"

function Test-PreviousSetup {
    return Test-Path $Script:ManifestPath
}

function Save-SetupManifest {
    param(
        [string[]]$ScoopBuckets,
        [string[]]$ScoopApps,
        [hashtable]$PinnedApps,
        [string]$RtoolsRenvironPath,
        [string]$PositronRBinaryPath
    )

    $manifestDir = Split-Path $Script:ManifestPath -Parent
    if (-not (Test-Path $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir | Out-Null
    }

    $manifest = [PSCustomObject]@{
        timestamp           = (Get-Date -Format "o")
        scoopBuckets         = $ScoopBuckets
        scoopApps            = $ScoopApps
        pinnedApps           = $PinnedApps
        rtoolsRenvironPath   = $RtoolsRenvironPath
        positronRBinaryPath  = $PositronRBinaryPath
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:ManifestPath
    Write-Host "Setup-status opgeslagen in $Script:ManifestPath" -ForegroundColor Green
}
