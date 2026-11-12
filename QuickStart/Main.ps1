. "$PSScriptRoot\Manifest.ps1"
. "$PSScriptRoot\Install.ps1"
. "$PSScriptRoot\Uninstall.ps1"
. "$PSScriptRoot\RtoolsRenviron.ps1"
. "$PSScriptRoot\PositronSettings.ps1"
. "$PSScriptRoot\Menu.ps1"

Show-QuickStartBanner

$projectRoot = Split-Path $PSScriptRoot -Parent

if (Test-PreviousSetup) {
    Write-Host "Eerdere installatie gevonden." -ForegroundColor Green
    Show-SetupMenu -ProjectRoot $projectRoot
    return
}

Write-Host "Geen eerdere installatie gevonden, dit is de eerste keer." -ForegroundColor Yellow
Write-Host ""
$doorgaan = Read-YesNo "Wil je de ontwikkelomgeving nu installeren?"

if (-not $doorgaan) {
    Write-Host ""
    Write-Host "Geen probleem, er is niets geinstalleerd. Tot de volgende keer!" -ForegroundColor Cyan
    return
}

Write-Host ""
Invoke-WithErrorLogging {
    Invoke-InstallFlow -ProjectRoot $projectRoot
    Open-ProjectInPositron -ProjectRoot $projectRoot
}
