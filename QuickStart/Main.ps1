Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  No Fairness Without Awareness QuickStart" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

. "$PSScriptRoot\Manifest.ps1"
. "$PSScriptRoot\Install.ps1"
. "$PSScriptRoot\PathUtils.ps1"
. "$PSScriptRoot\PositronSettings.ps1"
. "$PSScriptRoot\Menu.ps1"

if (Test-PreviousSetup) {
    Write-Host "Eerdere installatie gevonden." -ForegroundColor Green
} else {
    Write-Host "Geen eerdere installatie gevonden, dit is de eerste keer." -ForegroundColor Yellow
}

Write-Host ""
$doorgaan = Read-YesNo "Wil je de ontwikkelomgeving nu installeren?"

if (-not $doorgaan) {
    Write-Host ""
    Write-Host "Geen probleem, er is niets geinstalleerd. Tot de volgende keer!" -ForegroundColor Cyan
    return
}

Write-Host ""

if (Test-ScoopInstalled) {
    Write-Host "Scoop staat al geinstalleerd." -ForegroundColor Green
} else {
    Install-Scoop
}

Add-ScoopBucket "extras"
Install-ScoopApp "7zip"
Install-ScoopApp "git"
Install-ScoopApp "aria2"

$rVersion = "4.6.2"
$rtoolsVersion = "4.5.6768.6492"

Install-PinnedScoopApp "main/r@$rVersion"
Install-PinnedScoopApp "main/rtools@$rtoolsVersion"
Install-PinnedScoopApp "extras/quarto@1.11.9"
Install-PinnedScoopApp "extras/positron@2026.11.1-4"

Write-Host ""
$projectRoot = Split-Path $PSScriptRoot -Parent

$rtoolsBinPath = "$env:USERPROFILE\scoop\apps\rtools\$rtoolsVersion\x86_64-w64-mingw32.static.posix\bin"
Add-ProjectRtoolsPath -ProjectRoot $projectRoot -RtoolsBinPath $rtoolsBinPath

$rBinaryPath = "$env:USERPROFILE\scoop\apps\r\$rVersion\bin\x64\R.exe"
Set-ProjectPositronRBinary -ProjectRoot $projectRoot -RBinaryPath $rBinaryPath

Write-Host ""
Write-Host "Klaar met deze stap." -ForegroundColor Cyan
