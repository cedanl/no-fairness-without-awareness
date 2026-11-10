# Windows Dev Environment Setup — Planning

Branch: `windows-dev-env-setup`

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
- [x] **State-manifest**: JSON-bestand (bv. `%USERPROFILE%\.cedanl-devsetup\state.json`)
      met daarin: geïnstalleerde scoop-apps, toegevoegde buckets, de exacte
      PATH-waarde die is toegevoegd, R-versie, timestamp. Bepaalt of `Main.ps1`
      de install-flow of het menu toont, en is de basis voor precieze uninstall.
- [x] **PATH-afhandeling Rtools**: PATH-entry wijst naar de **exacte gepinde
      versie-map** (`%USERPROFILE%\scoop\apps\rtools\4.5.6768.6492\x86_64-w64-mingw32.static.posix\bin`),
      niet naar `current` — Scoop bewaart oudere versies op schijf, dus dit
      blijft werken ook als `current` ooit verschuift door iets anders.
      Alleen toevoegen indien afwezig (exacte string-match); later ook
      opslaan in manifest zodat uninstall precies déze entry weer verwijdert.
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
- [x] **Positron R-detectie** (via Context7-onderzoek): geen workspace
      settings.json-sleutel voor R-path (bestaat niet zoals bij Python's
      `python.interpreters.include`). Positron auto-discovert interpreters via
      PATH-scan, en Scoop plaatst shims al in de user PATH — R zou dus
      automatisch gevonden moeten worden. Vangnet: instructie tonen
      ("als R niet verschijnt: Command Palette > Discover All Interpreters").
      Géén aparte settings.json-schrijfstap meer nodig.
- [x] **Na installatie**: automatisch Positron openen met dit project.
      Menu-optie "Open project" doet dit ook bij latere runs.

## 2. Open beslissingen

- [ ] **Naamgevingsconventie bestanden**: PascalCase voor alle `.ps1`/`.bat`
      (voorstel, nog niet bevestigd) vs. kebab-case (bv. `quick-start.bat`).
- [ ] **UX-flow bevestigen**: klopt de ASCII-flow (zie hieronder) met
      install-progress per stap en uninstall-bevestiging, of moet er een
      stap/scherm bij of af?
- [ ] **Scoop zelf wel/niet verwijderen bij uninstall** — raakt direct de
      "alleen weghalen wat wij installeerden"-eis. Risico als we het wél
      verwijderen: als gebruiker na onze install zelf nog andere apps via
      Scoop heeft toegevoegd, raken die dan ook hun package manager kwijt.
- [x] **Versiepinning-strategie** — besloten: `r@4.6.2`, `rtools@4.5.6768.6492`,
      `quarto@1.11.9`, `positron@2026.11.1-4` worden gepind (exacte versie via
      `scoop install bucket/app@versie`), 7zip/git/aria2 niet.
- [ ] **Bucket-vertrouwen**: rtools/positron/quarto/specifieke R-versies staan
      niet in Scoop's officiële `main`-bucket maar in community-buckets
      (`extras`/`versions`). Akkoord om die te vertrouwen voor een org-tool?
- [ ] **Elevatie/rechten harde eis**: bevestigen dat niets ooit een
      UAC-prompt mag tonen (alles user-scope, zoals Scoop by design doet).
- [ ] **Foutafhandeling bij gedeeltelijke install**: wat gebeurt er als
      stap 4/7 faalt (bv. geen internet)? Moet het script kunnen hervatten,
      of altijd vanaf nul opnieuw beginnen?

## 3. UX-flow (concept, zie open vraag hierboven)

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
- [ ] Functies om `state.json` daadwerkelijk te schrijven/updaten (welke apps,
      buckets, PATH-entry zijn toegevoegd)

### QuickStart/Install.ps1
- [x] Scoop bootstrap (`Test-ScoopInstalled` + `Install-Scoop`)
- [x] Bucket toevoegen (`Add-ScoopBucket "extras"`)
- [x] Apps installeren: 7zip, git, aria2 (`Install-ScoopApp`)
- [x] Gepinde installs: r, rtools, quarto, positron (`Install-PinnedScoopApp`,
      zonder `hold` — zie beslissing hierboven)
- [x] Idempotent getest: Scoop's eigen "already installed"-gedrag gebruikt
      i.p.v. eigen (onbetrouwbare) detectie
- [ ] Per stap: resultaat wegschrijven naar manifest

### QuickStart/PathUtils.ps1
- [x] `Test-UserPathContains` / `Add-UserPathEntry` (exact string-match, user-scope)
- [ ] Verwijderfunctie voor uninstall (verwijdert alleen de eigen entry)

### QuickStart/PositronSettings.ps1
- [ ] Positron openen met dit project als workspace
- [ ] Fallback-instructie tonen (Discover All Interpreters)

### QuickStart/Menu.ps1
- [x] `Read-YesNo`: J/N-prompt met validatie (gebruikt voor install-bevestiging)
- [ ] Menu-opties voor latere runs: Open project / Herinstalleer / Uninstall / Afsluiten
- [ ] Bevestigingsstap vóór uninstall

### QuickStart/Uninstall.ps1
- [ ] Nog niet gestart. Alleen apps/buckets uit manifest verwijderen
- [ ] PATH-entry verwijderen via `PathUtils.ps1`
- [ ] Scoop zelf verwijderen? (afhankelijk van open vraag §2)
- [ ] Manifest opruimen na succesvolle uninstall

### QuickStart/Main.ps1
- [x] Splash → pre-flight check → J/N-bevestiging → Scoop/bucket/apps →
      gepinde apps → Rtools PATH-entry
- [ ] Routering naar menu bij bestaande installatie (nu altijd install-flow)
- [ ] Centrale foutafhandeling/logging

## 5. Testen
- [ ] Schone Windows-omgeving: volledige eerste install
- [ ] Tweede run toont menu correct
- [ ] Uninstall verwijdert exact de juiste apps + PATH-entry, laat overige
      gebruikersinstellingen ongemoeid
- [ ] Positron opent project en vindt R automatisch via PATH

## 6. Documentatie
- [ ] `QuickStart/README.md`: wat doet dit, hoe gebruik je het, hoe uninstall je
- [ ] Verwijzing vanuit hoofd-`README.md` naar `QuickStart.bat`
