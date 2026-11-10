function Test-UserPathContains {
    param([string]$Value)

    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $entries = $currentPath -split ';'
    return $entries -contains $Value
}

function Add-UserPathEntry {
    param([string]$Value)

    if (Test-UserPathContains $Value) {
        Write-Host "PATH bevat deze map al: $Value" -ForegroundColor Green
        return
    }

    Write-Host "PATH-entry toevoegen: $Value" -ForegroundColor Cyan
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = "$currentPath;$Value"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}
