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

function Invoke-InstallFlow {
    param([string]$ProjectRoot)

    $scoopPreExisting = Test-ScoopInstalled
    if ($scoopPreExisting) {
        Write-Host "Scoop staat al geinstalleerd." -ForegroundColor Green
    } else {
        Install-Scoop
    }

    Write-Host ""
    Write-Host "Let op: rtools, positron, quarto en deze R-versie komen uit Scoop's" -ForegroundColor DarkYellow
    Write-Host "community-buckets ('extras'), niet uit Scoop's officiele 'main'-bucket." -ForegroundColor DarkYellow
    Write-Host ""

    Add-ScoopBucket "extras"
    Install-ScoopApp "7zip"
    Install-ScoopApp "git"
    Install-ScoopApp "aria2"

    $rVersion = "4.6.2"
    $rtoolsVersion = "4.5.6768.6492"
    $quartoVersion = "1.11.9"
    $positronVersion = "2026.11.1-4"

    Install-PinnedScoopApp "main/r@$rVersion"
    Install-PinnedScoopApp "main/rtools@$rtoolsVersion"
    Install-PinnedScoopApp "extras/quarto@$quartoVersion"
    Install-PinnedScoopApp "extras/positron@$positronVersion"

    Write-Host ""
    $rtoolsBinPath = "$env:USERPROFILE\scoop\apps\rtools\$rtoolsVersion\x86_64-w64-mingw32.static.posix\bin"
    Add-ProjectRtoolsPath -ProjectRoot $ProjectRoot -RtoolsBinPath $rtoolsBinPath

    $rBinaryPath = "$env:USERPROFILE\scoop\apps\r\$rVersion\bin\x64\R.exe"
    Set-ProjectPositronRBinary -ProjectRoot $ProjectRoot -RBinaryPath $rBinaryPath

    Save-SetupManifest `
        -ScoopPreExisting $scoopPreExisting `
        -ScoopBuckets @("extras") `
        -ScoopApps @("7zip", "git", "aria2") `
        -PinnedApps @{ r = $rVersion; rtools = $rtoolsVersion; quarto = $quartoVersion; positron = $positronVersion } `
        -RtoolsRenvironPath $rtoolsBinPath `
        -PositronRBinaryPath $rBinaryPath

    Write-Host ""
    Write-Host "Klaar met deze stap." -ForegroundColor Cyan
}
