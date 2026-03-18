# nfwa 0.2.0 (Development)

## Breaking Changes

* **Decodering verwijderd uit package (Issue #15)** - nfwa decodeert geen vooropleidings- of ISAT-codes meer; die verantwoordelijkheid ligt nu bij het 1cijferho project.
  * `analyze_fairness()` en `transform_data()` accepteren nu een `opleidingscode` (ISAT-code) in plaats van `opleidingsnaam` voor het filteren van data
  * `opleidingsnaam` blijft beschikbaar als display-parameter voor het PDF rapport
  * De EV-data moet het enriched formaat zijn (kolom `hoogste_vooropleiding_omschrijving` gevuld)
  * `Dec_vopl.csv` en `Dec_isat.csv` zijn verwijderd uit `inst/metadata/dec/`
  * `read_metadata()` geeft geen `dec_vopl` of `dec_isat` meer terug

## Major Improvements

* **EOI Parameter** - EOI (Eerste jaar Opleiding/Instelling) nu zichtbaar in rapporten
  * `run_nfwa()` accepteert nu `eoi` parameter
  * EOI wordt opgeslagen in `analysis_metadata.rds`
  * Automatisch weergegeven in Bijlage D: Technische Details van PDF rapport
  * Pipeline: `analyze_fairness()` → `run_nfwa()` → `analysis_metadata` → PDF

* **Enhanced PDF Reports** - PDF rapporten nu toegankelijk voor niet-technische lezers (Issue #7)
  * **Uitgebreide Inleiding**:
    - "Wat is een kansengelijkheidsanalyse?" - Uitleg van bias in onderwijscontext
    - "Hoe werkt deze analyse?" - 3-staps proces met analogieën (thermometer metafoor)
  * **Verbeterde Methodologie** in begrijpelijke taal:
    - Data voorbereiding: uitleg retentie en gevoelige variabelen
    - Model training: Logistische Regressie en Random Forest uitgelegd zonder jargon
    - Fairness evaluatie: 4 metrieken met concrete voorbeelden
    - Bias classificatie: FRN scores met praktische interpretatie
    - Referentiegroep: waarom gekozen, hoe gebruikt, weergave in tabel (NTB)
  * **Belangrijke Overwegingen** uitgebreid:
    - Data-kwaliteit met praktische voorbeelden
    - Minimale groepsgrootte rationale (15 studenten)
    - Onderscheid bias in data vs. discriminatie
    - Wat bevindingen NIET zeggen
  * **Nieuwe sectie: "Hoe te Interpreteren?"**:
    - Wat te doen bij geconstateerde bias (systemen, didactiek, data)
    - Wat te doen zonder bias
    - Vervolgstappen: diepte-onderzoek, interventies, monitoring
    - Beperkingen van de analyse
  * **Uitgebreid Glossarium**: 22 termen (was 9)
    - Machine learning concepten uitgelegd
    - Fairness metrieken verduidelijkt
    - Onderwijs-specifieke terminologie
  * **Gecorrigeerde Visualisatie-uitleg**:
    - Fairness staafdiagram correct uitgelegd (verschillen t.o.v. referentie bij 0.0, niet ratio's bij 1.0)
    - Referentiegroep concept toegelicht in beide Methodologie en Bijlage A

* **Analysis Metadata** - `run_nfwa()` slaat nu uitgebreide metadata op
  * Aantal studenten
  * Gekozen model en prestatie (AUC)
  * Analyse parameters en datum
  * **EOI parameter** (nieuw)
  * Automatisch ingeladen in PDF template

## Documentation

* Mapping van GitHub Issue #7 requirements naar implementatie
* Roxygen documentatie bijgewerkt voor nieuwe `eoi` parameter in `run_nfwa()`

# nfwa 0.1.0

* Eerste release
* Fairness-analyse pipeline geïmplementeerd met DALEX en fairmodels
* Ondersteuning voor logistische regressie en random forest modellen
* Geautomatiseerde berekening en visualisatie van fairness-metrieken
* PDF rapportgeneratie met Quarto via `render_report()` functie
* Metadata-gestuurde variabele transformatie
* Functies voor verwerking van 1CHO onderwijsdata
* Quarto template inbegrepen in package voor professionele PDF rapporten
