# QuickStart

Installeert de Windows-devomgeving (R, Rtools, Quarto, Positron) via Scoop.
Dubbelklik `QuickStart.bat` in de repo-root. Opnieuw draaien = repareren.

```
QuickStart/
  Main.ps1               entrypoint: routeert naar install-flow of menu
  Install.ps1             Scoop + app-installs (Invoke-InstallFlow)
  Uninstall.ps1           alles weer verwijderen (Invoke-UninstallFlow)
  Menu.ps1                banner, J/N-prompt, menu bij latere runs
  Manifest.ps1            state.json + error.log
  RtoolsRenviron.ps1      Rtools-pad in project .Renviron
  PositronSettings.ps1    R-pad in .vscode/settings.json, Positron openen
```

Status/logs staan in `%USERPROFILE%\.cedanl-devsetup\`. Zie `../planning.md`
voor de volledige architectuur en openstaande beslissingen.
