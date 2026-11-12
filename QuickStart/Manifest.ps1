$Script:ManifestPath = "$env:USERPROFILE\.cedanl-devsetup\state.json"
$Script:ErrorLogPath = "$env:USERPROFILE\.cedanl-devsetup\error.log"

function Write-SetupError {
    param([string]$Message)

    $logDir = Split-Path $Script:ErrorLogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }

    Add-Content -Path $Script:ErrorLogPath -Value "[$(Get-Date -Format 'o')] $Message"
}

function Invoke-WithErrorLogging {
    param([scriptblock]$Action)

    try {
        & $Action
    } catch {
        Write-SetupError -Message $_.Exception.Message
        Write-Host ""
        Write-Host "Er ging iets mis. Details staan in $Script:ErrorLogPath" -ForegroundColor Red
        Write-Host "Probeer het opnieuw via QuickStart.bat." -ForegroundColor Yellow
    }
}

function Test-PreviousSetup {
    return Test-Path $Script:ManifestPath
}

function Save-SetupManifest {
    param(
        [bool]$ScoopPreExisting,
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
        scoopPreExisting    = $ScoopPreExisting
        scoopBuckets         = $ScoopBuckets
        scoopApps            = $ScoopApps
        pinnedApps           = $PinnedApps
        rtoolsRenvironPath   = $RtoolsRenvironPath
        positronRBinaryPath  = $PositronRBinaryPath
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:ManifestPath
    Write-Host "Setup-status opgeslagen in $Script:ManifestPath" -ForegroundColor Green
}

function Get-SetupManifest {
    if (-not (Test-PreviousSetup)) {
        return $null
    }
    return Get-Content $Script:ManifestPath -Raw | ConvertFrom-Json
}

function Remove-SetupManifest {
    if (Test-Path $Script:ManifestPath) {
        Remove-Item -Path $Script:ManifestPath -Force
        Write-Host "Manifest ($Script:ManifestPath) verwijderd." -ForegroundColor Green
    }
}
