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

function Show-QuickStartBanner {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "     No Fairness Without Awareness" -ForegroundColor Cyan
    Write-Host "              QuickStart" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "               C E D A" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
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
                Show-QuickStartBanner
                try {
                    Invoke-InstallFlow -ProjectRoot $ProjectRoot
                } catch {
                    Write-SetupError -Message $_.Exception.Message
                    Write-Host ""
                    Write-Host "Er ging iets mis. Details staan in $Script:ErrorLogPath" -ForegroundColor Red
                }
                return
            }
            "3" {
                Write-Host ""
                $bevestig = Read-YesNo "Weet je zeker dat je alles wilt verwijderen?"
                if ($bevestig) {
                    try {
                        Invoke-UninstallFlow -ProjectRoot $ProjectRoot
                    } catch {
                        Write-SetupError -Message $_.Exception.Message
                        Write-Host ""
                        Write-Host "Er ging iets mis. Details staan in $Script:ErrorLogPath" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Uninstall geannuleerd." -ForegroundColor Green
                }
                return
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
