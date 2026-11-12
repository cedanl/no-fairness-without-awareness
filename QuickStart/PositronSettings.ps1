function Set-ProjectPositronRBinary {
    param([string]$ProjectRoot, [string]$RBinaryPath)

    $vscodeDir = Join-Path $ProjectRoot ".vscode"
    $settingsPath = Join-Path $vscodeDir "settings.json"
    $key = "positron.r.customBinaries"
    $normalizedPath = $RBinaryPath -replace '\\', '/'

    if (-not (Test-Path $vscodeDir)) {
        New-Item -ItemType Directory -Path $vscodeDir | Out-Null
    }

    $settings = if (Test-Path $settingsPath) {
        Get-Content $settingsPath -Raw | ConvertFrom-Json
    } else {
        [PSCustomObject]@{}
    }

    $current = $settings.$key
    if ($current -is [array] -and $current.Count -eq 1 -and $current[0] -eq $normalizedPath) {
        Write-Host ".vscode/settings.json bevat dit R-pad al." -ForegroundColor Green
        return
    }

    Write-Host "Positron R-pad instellen in .vscode/settings.json: $normalizedPath" -ForegroundColor Cyan

    if ($settings.PSObject.Properties.Name -contains $key) {
        $settings.$key = @($normalizedPath)
    } else {
        $settings | Add-Member -MemberType NoteProperty -Name $key -Value @($normalizedPath)
    }

    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
}

function Remove-ProjectPositronRBinary {
    param([string]$ProjectRoot)

    $settingsPath = Join-Path $ProjectRoot ".vscode\settings.json"
    $key = "positron.r.customBinaries"

    if (-not (Test-Path $settingsPath)) {
        return
    }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if ($settings.PSObject.Properties.Name -notcontains $key) {
        return
    }

    Write-Host "$key verwijderen uit .vscode/settings.json." -ForegroundColor Cyan
    $settings.PSObject.Properties.Remove($key)
    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
}

function Open-ProjectInPositron {
    param([string]$ProjectRoot)

    Write-Host "Positron openen met dit project..." -ForegroundColor Cyan
    positron $ProjectRoot

    Write-Host ""
    Write-Host "Zie je R niet in de interpreter-lijst? Command Palette (Ctrl+Shift+P)" -ForegroundColor DarkYellow
    Write-Host "> 'Discover All Interpreters'." -ForegroundColor DarkYellow
}
