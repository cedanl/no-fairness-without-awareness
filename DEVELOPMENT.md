# Development Guide

Dit document is bedoeld voor ontwikkelaars die willen bijdragen aan het NFWA-project of de code willen aanpassen voor eigen gebruik.

---

## Inhoudsopgave

- [Ontwikkelomgeving opzetten](#ontwikkelomgeving-opzetten)
- [Architectuur](#architectuur)
- [Mappenstructuur](#mappenstructuur)
- [Data & Configuratie](#data--configuratie)
- [Code conventies](#code-conventies)
- [Uitbreiden](#uitbreiden)
- [Bijdragen](#bijdragen)
- [Problemen oplossen](#problemen-oplossen)

---

## Ontwikkelomgeving opzetten

### Vereisten

| Software | Beschrijving | Installatie |
|----------|--------------|-------------|
| R | Versie 4.3 of hoger | [cran.r-project.org](https://cran.r-project.org/) |
| RStudio | Aanbevolen IDE | [posit.co](https://posit.co/download/rstudio-desktop/) |
| Quarto | PDF-rapport generatie | [quarto.org](https://quarto.org/docs/get-started/) |
| LaTeX | Voor PDF-uitvoer | TinyTeX: `tinytex::install_tinytex()` |
| Rtools | Windows only | [cran.r-project.org/bin/windows/Rtools](https://cran.r-project.org/bin/windows/Rtools/) |
| Git | Versiebeheer | [git-scm.com](https://git-scm.com/) |

### Project klonen en packages installeren

```bash
git clone https://github.com/cedanl/no-fairness-without-awareness.git
cd no-fairness-without-awareness
```

```r
# In R/RStudio
install.packages("renv")
renv::restore()
```

### Environment variabelen (optioneel)

Het project gebruikt `LTA_ROOT` als environment variabele voor het standaard datapad:

```r
# In .Renviron (in je home directory of project root)
LTA_ROOT=/pad/naar/je/data
```

Of pas de paden direct aan in `main.R`.

---

## Architectuur

### Pipeline overzicht

```
 Parquet/CSV (data_ev, data_vakhavw)   metadata/
               │                        │
               └───────────┬────────────┘
                           v
                   +----------------+
                   | 01_read_       |
                   | metadata.R     |
                   +-------+--------+
                           |
                           v
                   +----------------+
                   | 02_transform_  |
                   | data.R         |
                   +-------+--------+
                           |
                           v
                   +----------------+
                   | 03_run_nfwa.R  |
                   +-------+--------+
                           |
                           v
                   +----------------+
                   | 04_render_pdf. |
                   | qmd            |
                   +-------+--------+
                           |
                           v
                      output/
```

### main.R stappen

1. **Configuratie** - `opleidingsnaam`, `eoi`, `opleidingsvorm` instellen
2. **Packages** - `renv::restore()` voor reproduceerbare omgeving
3. **Metadata** - lookups en variabele-definities laden
4. **Transformatie** - data verrijken en voorbereiden
5. **Samenvattingen** - beschrijvende statistieken genereren
6. **Fairness-analyse** - modellen trainen en fairness-metrieken berekenen
7. **Rapport** - PDF genereren via Quarto

### Modellering

- **Modellen**: Logistische regressie (glmnet) en Random Forest (ranger)
- **Framework**: tidymodels
- **Selectie**: Beste model op basis van ROC AUC
- **Fairness**: Statistical Parity, Equal Opportunity, Predictive Equality, Predictive Parity

---

## Mappenstructuur

```
project/
├── main.R          # Startpunt - coördineert de pipeline
├── scripts/        # Genummerde fase-scripts (01_, 02_, etc.)
├── R/              # Herbruikbare functies
├── config/         # Configuratie (kleuren, settings)
├── metadata/       # Lookup-tabellen en variabele-definities
├── output/         # Gegenereerde resultaten (runtime)
└── renv/           # Package management
```

### Conventies per map

| Map | Doel | Naamgeving |
|-----|------|------------|
| `scripts/` | Pipeline stappen | `XX_beschrijving.R` (genummerd) |
| `R/` | Herbruikbare functies | `actie_object.R` (bijv. `create_plot.R`) |
| `config/` | Configuratie | Beschrijvende naam |
| `metadata/` | Externe data/lookups | Beschrijvende naam |

---

## Data & Configuratie

### Vereiste invoerbestanden

- **EV (1CHO)** - Studentniveau instroom/retentie data (Parquet of CSV)
- **VAKHAVW (1CHO)** - Vakniveau data (Parquet of CSV)

Beide zijn output van het [1cijferho](https://github.com/cedanl/1cijferho) project.

### Metadata-bestanden

| Bestand | Doel |
|---------|------|
| `variabelen.xlsx` | Definieert modelvariabelen en gevoelige variabelen |
| `levels.xlsx` | Factor niveau ordeningen voor categorische variabelen |
| `APCG_*.csv` | Postcode naar APCG score lookup |
| `SES_*.csv` | Postcode naar SES score lookup |

### Variabelen configureren

In `metadata/variabelen.xlsx`:
- `Include = TRUE` → variabele opnemen in model
- `Sensitive = TRUE` → markeren voor fairness-analyse

---

## Code conventies

### Algemeen

- Gebruik `dplyr`-pipelines (`%>%` of `|>`) voor data manipulatie
- Volg tidymodels-idiomen voor modellering
- Functies in `R/`, scripts in `scripts/`

### Functie documentatie

Gebruik roxygen2-stijl waar mogelijk:

```r
#' Korte beschrijving
#'
#' @param x Beschrijving parameter
#' @return Beschrijving output
functie_naam <- function(x) {
}
```

### Package management

```r
# Na toevoegen nieuwe packages
renv::snapshot()

# Bij problemen
renv::restore()
```

---

## Uitbreiden

### Nieuwe functie toevoegen

1. Maak bestand in `R/` met beschrijvende naam
2. Schrijf functie met roxygen2 documentatie
3. Source in het relevante script

### Nieuwe gevoelige variabele

1. Open `metadata/variabelen.xlsx`
2. Zet `Sensitive = TRUE` voor de variabele
3. Pipeline pakt het automatisch op

### Nieuw model toevoegen

1. Bewerk `R/run_models.R`
2. Voeg model specificatie toe aan de workflow
3. Pipeline selecteert automatisch beste model

### Styling aanpassen

- Kleuren: `R/colors_data.R`
- Rapport layout: `scripts/04_render_pdf.qmd`

---

## Bijdragen

### Workflow

1. Fork de repository
2. Maak feature branch: `git checkout -b feature/beschrijving`
3. Commit wijzigingen
4. Push en open Pull Request

### Checklist

- [ ] Code volgt conventies
- [ ] `renv::snapshot()` bij nieuwe dependencies
- [ ] Getest met voorbeelddata

---

## Problemen oplossen

| Probleem | Oplossing |
|----------|-----------|
| Ontbrekende data-paden | Check `main.R` paden en `LTA_ROOT` |
| Quarto/TeX fouten | Installeer Quarto + `tinytex::install_tinytex()` |
| Package compilatie | `renv::restore()` + systeemtools (Rtools/Xcode) |
| Arrow installatie | `install.packages("arrow", repos = "https://apache.r-universe.dev")` |

### Debug

```r
sessionInfo()      # Package info
renv::status()     # renv status
Sys.getenv("LTA_ROOT")  # Environment check
```

### Hulp

Open een [GitHub Issue](https://github.com/cedanl/no-fairness-without-awareness/issues) met:
- Probleem beschrijving
- Stappen om te reproduceren
- `sessionInfo()` output
