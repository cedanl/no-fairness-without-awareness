function Invoke-UninstallFlow {
    param([string]$ProjectRoot)

    $manifest = Get-SetupManifest
    if (-not $manifest) {
        Write-Host "Geen installatie gevonden om te verwijderen." -ForegroundColor Yellow
        return
    }

    foreach ($app in $manifest.scoopApps) {
        Write-Host "App '$app' verwijderen..." -ForegroundColor Cyan
        scoop uninstall $app
    }

    foreach ($appName in $manifest.pinnedApps.PSObject.Properties.Name) {
        Write-Host "App '$appName' (gepind) verwijderen..." -ForegroundColor Cyan
        scoop uninstall $appName
    }

    foreach ($bucket in $manifest.scoopBuckets) {
        Write-Host "Bucket '$bucket' verwijderen..." -ForegroundColor Cyan
        scoop bucket rm $bucket
    }

    Remove-ProjectRtoolsPath -ProjectRoot $ProjectRoot
    Remove-ProjectPositronRBinary -ProjectRoot $ProjectRoot

    Write-Host ""
    if ($manifest.scoopPreExisting) {
        Write-Host "Scoop was al aanwezig vóór deze installatie - je gebruikt het mogelijk" -ForegroundColor DarkYellow
        Write-Host "ook voor andere projecten of apps." -ForegroundColor DarkYellow
        $eersteKeer = Read-YesNo "Wil je Scoop zelf OOK verwijderen?"
        $verwijderScoop = $eersteKeer -and (Read-YesNo "Zeker weten? Dit verwijdert Scoop en ALLE apps die ermee beheerd worden")
    } else {
        $verwijderScoop = Read-YesNo "Scoop zelf ook verwijderen? (is door deze installatie toegevoegd)"
    }

    if ($verwijderScoop) {
        Write-Host "Scoop verwijderen..." -ForegroundColor Cyan
        scoop uninstall scoop --purge
    } else {
        Write-Host "Scoop blijft staan." -ForegroundColor Green
    }

    Remove-SetupManifest

    Write-Host ""
    Write-Host "Uninstall voltooid." -ForegroundColor Cyan
}
