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
