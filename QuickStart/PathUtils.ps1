function Add-ProjectRtoolsPath {
    param([string]$ProjectRoot, [string]$RtoolsBinPath)

    $renvironPath = Join-Path $ProjectRoot ".Renviron"
    $marker = "# Rtools (added by QuickStart)"
    $line = "PATH=$RtoolsBinPath;" + '${PATH}'

    $lines = if (Test-Path $renvironPath) { @(Get-Content $renvironPath) } else { @() }

    if ($lines -contains $line) {
        Write-Host ".Renviron bevat deze Rtools PATH-regel al." -ForegroundColor Green
        return
    }

    # vorige Rtools-regel verwijderen, voor het geval de versie is gewijzigd
    $lines = $lines | Where-Object { $_ -ne $marker -and $_ -notmatch '^PATH=.*rtools' }

    Write-Host "Rtools PATH toevoegen aan project .Renviron: $RtoolsBinPath" -ForegroundColor Cyan
    Set-Content -Path $renvironPath -Value ($lines + $marker, $line)
}
