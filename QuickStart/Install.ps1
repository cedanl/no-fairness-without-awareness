function Test-ScoopInstalled {
    if (Test-Path "$env:USERPROFILE\scoop\shims\scoop.ps1") {
        return $true
    }
    return [bool](Get-Command scoop -ErrorAction SilentlyContinue)
}

function Install-Scoop {
    Write-Host "Scoop installeren..." -ForegroundColor Cyan
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

function Add-ScoopBucket {
    param([string]$Name)

    Write-Host "Bucket '$Name' toevoegen (of controleren)..." -ForegroundColor Cyan
    scoop bucket add $Name
}

function Install-ScoopApp {
    param([string]$Name)

    Write-Host "$Name installeren (of controleren)..." -ForegroundColor Cyan
    scoop install $Name
}

function Install-PinnedScoopApp {
    param([string]$VersionedName) # bv. "main/r@4.6.2"

    $bareName = ($VersionedName -split '/')[-1] -split '@' | Select-Object -First 1

    Write-Host "$bareName installeren (gepind op versie, of controleren)..." -ForegroundColor Cyan
    scoop install $VersionedName
}
