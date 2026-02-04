
## Pipeline in een oogopslag

```
 Parquet/CSV (df1cho, df1cho_vak)   metadata/ dictionaries
               │                            │
               └──────────────┬─────────────┘
                              v
                   +------------------------+
                   | scripts/01_read_       |
                   | metadata.R             |
                   |  - lees lookups        |
                   |  - markeer gevoelige   |
                   |    variabelen          |
                   +-----------+------------+
                               |
                               v
                   +------------------------+
                   | scripts/02_transform_  |
                   | data.R                 |
                   |  - verrijk APCG/SES    |
                   |  - selecteer variab.   |
                   |  - prep factor levels  |
                   +-----------+------------+
                               |
                               v
           +-------------------+-------------------+
           | scripts/03_run_nfwa.R                 |
           |  - split/train/valideer (glmnet,      |
           |    ranger)                            |
           |  - fairness-metrieken/tabellen/    |
           |    plots                              |
           +-------------------+-------------------+
                               |
                               v
                   +------------------------+
                   | scripts/04_render_pdf. |
                   | qmd (Quarto)           |
                   +-----------+------------+
                               |
                               v
               scripts/kansengelijkheid...pdf
```

```
main.R
  ├─ stelt instellingen in (opleiding, eoi, opleidingsvorm, cutoff)
  ├─ roept renv::restore() aan
  ├─ voert fase-scripts uit
  └─ schrijft resultaten naar output/
```

## Pipeline doorloop (main.R)

- **Invoer**: stel `opleidingsnaam`, `eoi` (inschrijvingsjaar), en `opleidingsvorm` in bovenaan `main.R`.
- **Data laden**: leest de studentniveau en vakniveau parquet-bestanden waar je naar verwijst in `main.R`.
- **Metadata**: `scripts/01_read_metadata.R` leest meta tabellen in (`metadata/`) en heeft output:
    - APCG (Armoede Probleem Cumulatie Gebied) & SES (Sociaal-Economische Status) verrijkingsdata
    - Variabelenlijst (`variables`) en gevoelige variabelen (`sensitive_variables`) gedefinieerd in `variabelen.xlsx`
    - Label-mappings (`mapping_newname`) en geordende factor-niveaus (`df_levels`)
    - Decodering opzoektabellen voor hercodering van opleidingsvelden
- **Transformeren**: `scripts/02_transform_data.R` past transformatioes toe (`R/transform_*`), verrijkt met APCG/SES, selecteert de modelvariabelen, en past gemiddelde-imputatie toe op numerieke NA's.
- **Steekproef**: `main.R` maakt momenteel een 50/50 behouden/niet-behouden subset voor snellere experimenten.
- **Beschrijvende statistieken**: `R/get_table_summary.R` bouwt gtsummary/flextable tabellen (`output/descriptive_table.png` en `output/sensitive_variables_descriptive_table.png`).
- **Fairness-analyse**: `scripts/03_run_nfwa.R` traint modellen, berekent fairness-diagnostiek per gevoelige variabele, slaat tabellen op (`output/result_table.png`), en geserialiseerde conclusies (`output/conclusions_list.rds`). Kleuren zijn gedefinieerd in `config/colors.R`.
- **Rapport**: Quarto rendert `scripts/04_render_pdf.qmd` naar `scripts/kansengelijkheidanalysis_<opleiding>_<vorm>.pdf`.

## Repository structuur

- `main.R` — startpunt dat de volledige pipeline coördineert.
- `scripts/` — fase-scripts (metadata, transformatie, NFWA-run, Quarto-rapport) plus gegenereerde PDF.
- `R/` — herbruikbare functies voor transformaties, modellering (`run_models.R`), fairness-plots/-tabellen, en styling-helpers.
- `config/colors.R` — kleurenpaletten voor plots/tabellen.
- `metadata/` — invoer-woordenboeken (APCG, SES, DEC, variabele-definities, factor-niveaus).
- `output/` — gegenereerde tabellen, plots, RDS-conclusies en uiteindelijke PDF (aangemaakt tijdens uitvoering).
- `renv*` — package lockfile en library-beheer.

## Data & Configuratie

- Vereiste invoer (door jou aan te leveren):
    - Parquet of CSV voor EV (1CHO) — instroom/retentie basis; output van project: [1cijferho](https://github.com/cedanl/1cijferho)
    - Parquet of CSV voor VAKHAVW (1CHO) — vakniveau detail
    - Metadata CSV/XLSX bestanden zitten al in `metadata/`
- Pas `main.R` aan om naar je databestanden te verwijzen (vervang de voorbeeldbestandsnamen)
- Pas `metadata/variabelen.xlsx` aan om modelvariabelen toe te voegen/verwijderen of nieuwe gevoelige velden te markeren; de pipeline leest dit automatisch.
- Factor-ordeningen komen uit `metadata/levels.xlsx`. Pas deze aan om weergave en fairness-samenvattingen te controleren.

## Hoe de modellering/fairness-stap werkt

- Splitst de data in train/test/validatie (`initial_validation_split` met stratificatie op `retentie`).
- Traint twee modellen via tidymodels: logistische regressie met elastic net (`glmnet`) en random forest (`ranger`), beide getuned op de validatieset.
- Kiest het beste model op basis van hoogste ROC AUC, past het vervolgens toe op de volledige trainingsdata (`last_fit`).
- Bouwt een verklaarbaar modelobject (`R/create_explain_lf.R`), vervolgens voor elke gevoelige variabele:
    - Selecteert de grootste subgroep als geprivilegieerde groep.
    - Berekent fairness-metrieken en bias-labels (`FRN_Bias`).
    - Rendert dichtheids- en fairness-plots plus een brede overzichtstabel.
- Conclusies per gevoelige variabele worden opgeslagen in `output/conclusions_list.rds` voor hergebruik in het rapport.

## Uitbreiden of verder ontwikkelen

- Nieuwe data-jaargangen: plaats nieuwe parquet/CSV-bestanden en werk de paden/bestandsnamen bij in `main.R`.
- Nieuwe gevoelige variabelen: markeer ze in `metadata/variabelen.xlsx` (`Sensitive = TRUE`); `main.R` pakt ze automatisch op.
- Model-aanpassingen:
    - Bewerk `R/run_models.R` om modellen toe te voegen of tuning-grids/recepten te wijzigen.
    - Pas de `cutoff` voor fairness-controles aan in de `run_nfwa()` aanroep binnen `main.R`.
- Styling:
    - Werk `config/colors.R` bij voor paletwijzigingen.
    - Pas `scripts/04_render_pdf.qmd` aan voor rapportlay-out.
- Mogelijke volgende features:
    - Shiny-interface: laad `df1cho`/`df1cho_vak` vanuit CSV-uploads, presenteer dropdowns voor `opleidingsnaam` en `opleidingsvorm` en voer de pipeline on demand uit.
    - Parameter UI: stel de fairness-cutoff, modelkeuzes en kleurenthema's beschikbaar als configureerbare invoer.
    - Caching/tussenopslagen: bewaar getransformeerde data om iteratieve runs te versnellen.
    - Multi-seed bootstrapping: voer de fairness-pipeline over meerdere seeds uit en aggregeer conclusies om onstabiele metrieken te spotten voordat je erop acteert.

## Reproduceerbaarheid & Conventies

- Package-versies zijn vergrendeld via `renv.lock`; houd `renv::snapshot()` up-to-date na dependency-wijzigingen.
- Functies leven onder `R/` en worden gesourced door de fase-scripts; voeg bij voorkeur nieuwe helpers daar toe.
- Outputs worden geschreven naar `output/`; houd gegenereerde artifacts uit versiebeheer tenzij bewust ingecheckt.
- Geef de voorkeur aan `dplyr`-pipelines en tidymodels-idiomen voor consistentie met bestaande code.

## Problemen oplossen

- **Ontbrekende data-paden**: controleer de parquet-locaties waarnaar verwezen wordt in `main.R`.
- **Quarto/TeX fouten**: zorg dat Quarto en een LaTeX-distributie geïnstalleerd zijn voor PDF-rendering.
- **Package-compilatieproblemen**: voer `renv::restore()` uit in een schone sessie en zorg dat systeembouwtools beschikbaar zijn voor packages zoals `arrow` of `glmnet`.
- **Rtools niet gevonden (Windows)**: installeer Rtools van de officiële CRAN-website en herstart RStudio.
