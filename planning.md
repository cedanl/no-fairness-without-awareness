# Windows Dev Environment Setup — Planning

Branch: `6-quickstart-installer`

Legenda: `[x]` = besloten/vastgelegd, `[ ]` = nog open (keuze of bouwtaak).

## 1. Architectuur (besloten)

- [x] **Entrypoint**: `QuickStart.bat` in de **repo-root** (niet in een submap) —
      direct zichtbaar en dubbelklikbaar zodra iemand de repo download.
- [x] **Geen gecompileerde .exe**: ps2exe-binaries worden regelmatig door
      Windows Defender/SmartScreen/browser-reputatie gezien als verdacht en
      kunnen **automatisch verwijderd** worden na download — niet alleen een
      waarschuwing. Een `.bat` + `.ps1` combinatie triggert dat gedrag niet.
- [x] `QuickStart.bat` roept aan: `powershell -ExecutionPolicy Bypass -File QuickStart\Main.ps1`
- [x] **Mapstructuur**: platte multi-file split, dot-sourced (geen `.psm1`
      modules, geen monoliet):
      ```
      QuickStart.bat
      QuickStart/
        Main.ps1              <- entrypoint, routeert install-flow vs menu
        Install.ps1
        Uninstall.ps1
        Menu.ps1
        PathUtils.ps1
        Manifest.ps1
        PositronSettings.ps1
      ```
- [x] **State-manifest**: JSON-bestand (`%USERPROFILE%\.cedanl-devsetup\state.json`)
      met daarin: toegevoegde buckets, geïnstalleerde scoop-apps, gepinde
      app-versies (r/rtools/quarto/positron), het Rtools-pad in `.Renviron`,
      het Positron R-binary-pad in `.vscode/settings.json`, timestamp.
      Bepaalt of `Main.ps1` de install-flow of het menu toont, en is de basis
      voor precieze uninstall. **Wordt pas geschreven na een volledig
      succesvolle run** (zie beslissing hieronder over foutafhandeling).
- [x] **PATH-afhandeling Rtools**: project-`.Renviron`-entry wijst naar de
      **exacte gepinde versie-map**
      (`%USERPROFILE%\scoop\apps\rtools\4.5.6768.6492\x86_64-w64-mingw32.static.posix\bin`),
      niet naar `current` — Scoop bewaart oudere versies op schijf, dus dit
      blijft werken ook als `current` ooit verschuift door iets anders.
      Alleen toevoegen/vervangen indien nodig (dedupe op exacte regel, oude
      Rtools-regel wordt vervangen bij versiewissel); staat ook in het
      manifest zodat uninstall weet welke regel te verwijderen.
- [x] **Geen `scoop hold`**: bewust weggelaten voor r/rtools/quarto/positron.
      Reden: het conflict-risico (een ander project op dezelfde machine met
      een eigen gepinde versie) wordt er niet door opgelost — dat is een
      fundamentele beperking van Scoop's `current`-model, met of zonder hold.
      Hold beschermde alleen tegen toekomstige drift via een losse
      `scoop update *`. Voor Rtools is dat al opgelost via de versie-vaste
      PATH hierboven. Voor R/Quarto/Positron (die nog via `current`/shims
      gevonden worden) accepteren we voorlopig dat risico — **"probleem voor
      later"**: kan later ook via een exact pad aangeroepen worden i.p.v.
      op `current`/hold te vertrouwen.
- [x] **Positron R-detectie** (herzien, eerdere aanname was onjuist): Positron
      heeft wél settings voor non-standaard R-locaties —
      `positron.r.customBinaries` (exact pad naar `R.exe`) en
      `positron.r.customRootFolders` (map met versie-submappen), zie
      https://positron.posit.co/r-installations. Scoop's shim-PATH maakt R
      meestal al vindbaar, maar om dat niet van toeval te laten afhangen
      schrijft `PositronSettings.ps1` het exacte, geresolvede pad naar
      `main/r@<versie>` naar `.vscode/settings.json` (`positron.r.customBinaries`).
      Dat bestand is **gitignored**: het pad bevat de Windows-gebruikersnaam
      (`%USERPROFILE%\scoop\...`), dus committen zou het voor ieder ander
      teamlid breken. Zelfde aanpak als Rtools' project-`.Renviron`.
- [x] **Na installatie**: automatisch Positron openen met dit project.
      Menu-optie "Open project" doet dit ook bij latere runs.
- [x] **Scoop's eigen output bij Herinstalleer**: bewust ongewijzigd gelaten.
      Scoop's eigen `WARN '<app>' is already installed`-regels blijven
      zichtbaar bij "Herinstalleer/repareer" — geen eigen onderdrukking
      of samenvatting daarvan gebouwd.

## 2. Open beslissingen

- [x] **Naamgevingsconventie bestanden** — de facto besloten: alle 6 bestaande
      `.ps1`-bestanden zijn consistent PascalCase, geen kebab-case gebruikt.
- [ ] **UX-flow bevestigen**: voorstel is om de `[n/7]`-voortgangsteller uit
      de ASCII-flow hieronder NIET te bouwen — elke helper-functie print al
      een eigen statusregel, een teller erbovenop is bijhoud-overhead voor
      weinig winst. Nog niet definitief bevestigd.
- [x] **Scoop zelf wel/niet verwijderen bij uninstall** — besloten: hangt af
      van of Scoop al aanwezig was vóór onze install. Dat wordt vastgelegd in
      `state.json` (`scoopPreExisting`, gezet in `Invoke-InstallFlow` vóórdat
      `Install-Scoop` draait). Bij uninstall: als wij Scoop zelf installeerden
      → één keer vragen. Als Scoop al bestond → twee keer vragen (dubbele
      bevestiging), omdat de gebruiker dan mogelijk eigen andere apps via
      Scoop beheert die anders ook hun package manager kwijtraken.
- [x] **Versiepinning-strategie** — besloten: `r@4.6.2`, `rtools@4.5.6768.6492`,
      `quarto@1.11.9`, `positron@2026.11.1-4` worden gepind (exacte versie via
      `scoop install bucket/app@versie`), 7zip/git/aria2 niet.
- [x] **Bucket-vertrouwen**: rtools/positron/quarto/specifieke R-versies staan
      niet in Scoop's officiële `main`-bucket maar in community-buckets
      (`extras`/`versions`). Besloten: akkoord, mét een eenmalige disclaimer
      tijdens install (geen extra bevestigingsstap, gewoon een duidelijke
      regel dat dit community-buckets zijn).
- [x] **Elevatie/rechten harde eis**: bevestigd — nooit een UAC-prompt. Geen
      bouwtaak: Scoop's model is by design user-scope, dus dit geldt al voor
      alles wat we doen (bootstrap, buckets, installs, `.Renviron`,
      `.vscode/settings.json`, `state.json` staan allemaal in
      user-schrijfbare locaties).
- [x] **Foutafhandeling bij gedeeltelijke install** — besloten: geen
      resume-logica. `state.json` wordt alleen aan het eind van een volledig
      succesvolle run geschreven, dus een mislukte run (bv. stap 4/7 zonder
      internet) laat geen manifest achter en de volgende keer wordt gewoon
      de hele install-flow opnieuw doorlopen. Dat is veilig omdat elke stap
      al idempotent is (Scoop's eigen "already installed"-check,
      dedupe in `.Renviron`/`.vscode/settings.json`).

## 3. UX-flow (concept, zie open vraag hierboven)

**Let op**: onderstaande `[n/7]`-voortgangsteller is nog aspirational — de
huidige `Invoke-InstallFlow` print alleen de losse `Write-Host`-regels per
helper-functie, geen genummerde stappenteller. Of die teller er nog bij komt
hangt af van de open "UX-flow bevestigen"-vraag.

```
=== EERSTE RUN (geen manifest) ===
Geen eerdere installatie gevonden.
Dit installeert: Scoop, 7zip, aria2, git, R (pinned), Rtools, Positron, Quarto
Doorgaan? (J/N): J

[1/7] Scoop installeren...     OK
[2/7] Buckets toevoegen...     OK
[3/7] 7zip + aria2 + git...    OK
[4/7] R (pinned) ...           OK
[5/7] Rtools...                OK
[6/7] PATH-entry toevoegen...  OK
[7/7] Positron + Quarto...     OK

Installatie voltooid. Project wordt geopend in Positron...

=== LATERE RUN (manifest bestaat) ===
Omgeving al geinstalleerd (sinds 2026-11-10)
  [1] Open project in Positron
  [2] Herinstalleer / repareer
  [3] Verwijder alles (uninstall)
  [4] Afsluiten
```

## 4. Implementatie-checklist (per bestand)

### QuickStart.bat
- [x] Root-bestand, roept `powershell -ExecutionPolicy Bypass -File QuickStart\Main.ps1`

### QuickStart/Manifest.ps1
- [x] `Test-PreviousSetup`: check of manifest-bestand bestaat (pre-flight)
- [x] `Save-SetupManifest`: schrijft `scoopPreExisting`, buckets, apps,
      gepinde versies, `.Renviron`-pad en Positron R-binary-pad naar
      `state.json` — atomisch aan het eind van een succesvolle run (zie §2)
- [x] `Get-SetupManifest` / `Remove-SetupManifest`: lezen/opruimen voor
      `Uninstall.ps1`
- [x] `Write-SetupError`: logt naar `%USERPROFILE%\.cedanl-devsetup\error.log`,
      gebruikt door de try/catch in `Main.ps1` en `Menu.ps1`

### QuickStart/Install.ps1
- [x] Scoop bootstrap (`Test-ScoopInstalled` + `Install-Scoop`)
- [x] Bucket toevoegen (`Add-ScoopBucket "extras"`)
- [x] Apps installeren: 7zip, git, aria2 (`Install-ScoopApp`)
- [x] Gepinde installs: r, rtools, quarto, positron (`Install-PinnedScoopApp`,
      zonder `hold` — zie beslissing hierboven)
- [x] `Invoke-InstallFlow`: de hele install-sequentie (Scoop → buckets → apps →
      gepinde apps → `.Renviron` → `.vscode/settings.json` → manifest) als
      één herbruikbare functie, aangeroepen bij eerste install én vanuit het
      menu's "Herinstalleer/repareer"
- [x] Idempotent getest: Scoop's eigen "already installed"-gedrag gebruikt
      i.p.v. eigen (onbetrouwbare) detectie
- [x] ~~Per stap wegschrijven naar manifest~~ — vervangen door één atomische
      `Save-SetupManifest`-call aan het eind, zie `Manifest.ps1` en §2

### QuickStart/PathUtils.ps1
- [x] `Add-ProjectRtoolsPath` (schrijft Rtools-bin naar project-`.Renviron`
      i.p.v. de globale user PATH — Rtools is het enige dat niet via Scoop's
      eigen shim-PATH gevonden wordt; R en Quarto hebben dit niet nodig)
- [x] `Remove-ProjectRtoolsPath` (verwijdert alleen de eigen `.Renviron`-regel)

### QuickStart/PositronSettings.ps1
- [x] `Set-ProjectPositronRBinary` (schrijft `positron.r.customBinaries` naar
      project-`.vscode/settings.json`, merget i.p.v. overschrijft, gitignored)
- [x] `Remove-ProjectPositronRBinary` (verwijdert alleen de eigen key)
- [x] `Open-ProjectInPositron` (roept de `positron`-shim aan met het
      projectpad; wordt automatisch aangeroepen na eerste install en vanuit
      het menu's "Open project")
- [x] Fallback-instructie tonen (Discover All Interpreters) — vaste melding
      na het openen van Positron; kan niet echt detecteren of het nodig is
      (geen manier om Positron's interpreter-lijst vanuit PowerShell te lezen)

### QuickStart/Menu.ps1
- [x] `Read-YesNo`: J/N-prompt met validatie (gebruikt voor install-bevestiging)
- [x] `Show-QuickStartBanner`: titel + CEDA-branding (letter-spaced, geen
      blokletters — risico op uitlijnproblemen in smalle terminal). Draait
      bij opstarten (`Main.ps1`) én opnieuw bij "Herinstalleer" vanuit het
      menu, zodat 'ie niet in oude scroll-geschiedenis wegraakt.
- [x] `Show-SetupMenu`: Open project (werkend) / Herinstalleer (werkend,
      roept `Invoke-InstallFlow` opnieuw aan) / Uninstall (werkend,
      roept `Invoke-UninstallFlow` aan) / Afsluiten
- [x] Bevestigingsstap vóór uninstall (J/N via `Read-YesNo`)

### QuickStart/Uninstall.ps1
- [x] `Invoke-UninstallFlow`: verwijdert scoop-apps/buckets uit manifest,
      de `.Renviron`-regel, de `.vscode/settings.json`-key, en ruimt
      `state.json` op
- [x] Scoop zelf verwijderen — enkel vragen als wij 'm installeerden
      (`scoopPreExisting: false`), dubbel bevestigen als hij al bestond
      (zie §2-beslissing)

### QuickStart/Main.ps1
- [x] Routering: manifest bestaat → `Show-SetupMenu`; anders → J/N-bevestiging
      → `Invoke-InstallFlow` → automatisch Positron openen
- [x] Centrale foutafhandeling/logging: try/catch rond `Invoke-InstallFlow`/
      `Invoke-UninstallFlow` (in `Main.ps1` én `Menu.ps1`), logt naar
      `Write-SetupError` i.p.v. een losse PowerShell-stacktrace te tonen

## 5. Testen
- [ ] Schone Windows-omgeving: volledige eerste install
- [ ] Tweede run toont menu correct
- [ ] Uninstall verwijdert exact de juiste apps + PATH-entry, laat overige
      gebruikersinstellingen ongemoeid
- [ ] Positron opent project en vindt R: via `.vscode/settings.json`
      (`positron.r.customBinaries`) én, los daarvan, via Scoop's shim-PATH

## 6. Documentatie
- [ ] `QuickStart/README.md`: wat doet dit, hoe gebruik je het, hoe uninstall je
- [ ] Verwijzing vanuit hoofd-`README.md` naar `QuickStart.bat`
