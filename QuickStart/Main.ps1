Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  No Fairness Without Awareness QuickStart" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

. "$PSScriptRoot\Manifest.ps1"
. "$PSScriptRoot\Install.ps1"
. "$PSScriptRoot\Uninstall.ps1"
. "$PSScriptRoot\PathUtils.ps1"
. "$PSScriptRoot\PositronSettings.ps1"
. "$PSScriptRoot\Menu.ps1"

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
try {
    Invoke-InstallFlow -ProjectRoot $projectRoot
    Open-ProjectInPositron -ProjectRoot $projectRoot
} catch {
    Write-SetupError -Message $_.Exception.Message
    Write-Host ""
    Write-Host "Er ging iets mis tijdens de installatie." -ForegroundColor Red
    Write-Host "Details staan in $Script:ErrorLogPath" -ForegroundColor Red
    Write-Host "Probeer QuickStart opnieuw te draaien." -ForegroundColor Yellow
}
