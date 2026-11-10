function Read-YesNo {
    param(
        [string]$Prompt
    )

    while ($true) {
        $answer = Read-Host "$Prompt [J]a / [N]ee"
        switch ($answer.Trim().ToLower()) {
            "j"   { return $true }
            "ja"  { return $true }
            "n"   { return $false }
            "nee" { return $false }
            default {
                Write-Host "Sorry, dat snap ik niet. Typ 'J' of 'N'." -ForegroundColor Yellow
            }
        }
    }
}

function Show-SetupMenu {
    param([string]$ProjectRoot)

    while ($true) {
        Write-Host ""
        Write-Host "Omgeving is al geinstalleerd." -ForegroundColor Green
        Write-Host "  [1] Open project in Positron"
        Write-Host "  [2] Herinstalleer / repareer"
        Write-Host "  [3] Verwijder alles (uninstall)"
        Write-Host "  [4] Afsluiten"
        $keuze = Read-Host "Kies een optie (1-4)"

        switch ($keuze.Trim()) {
            "1" {
                Open-ProjectInPositron -ProjectRoot $ProjectRoot
                return
            }
            "2" {
                Invoke-InstallFlow -ProjectRoot $ProjectRoot
                return
            }
            "3" {
                Write-Host ""
                Write-Host "Uninstall is nog niet geimplementeerd." -ForegroundColor Yellow
            }
            "4" {
                return
            }
            default {
                Write-Host "Sorry, dat snap ik niet. Kies 1, 2, 3 of 4." -ForegroundColor Yellow
            }
        }
    }
}
