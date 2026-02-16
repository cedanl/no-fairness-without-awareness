<h1>No Fairness Without Awareness (NFWA)</h1>

<p>R package voor kansengelijkheidsanalyse in het hoger onderwijs</p>

<p><a href="#"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&amp;logoColor=white" alt="Windows"/></a> <a href="#"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&amp;logoColor=F0F0F0" alt="macOS"/></a> <a href="#"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&amp;logoColor=black" alt="Linux"/></a> <img src="https://badgen.net/github/last-commit/cedanl/no-fairness-without-awareness" alt="GitHub Last Commit"/> <img src="https://badgen.net/github/contributors/cedanl/no-fairness-without-awareness" alt="Contributors"/> <img src="https://img.shields.io/github/license/cedanl/no-fairness-without-awareness" alt="GitHub License"/></p>

## Over het package

Het **NFWA** (No Fairness Without Awareness) package is een R package ontwikkeld op basis van het onderzoek van het lectoraat Learning Technology & Analytics (LTA) van De Haagse Hogeschool. Het LTA heeft tot doel kansengelijkheid voor studenten te verhogen met behulp van learning analytics en inzet van learning technology.

Het lectoraat heeft een onderzoeksmethode ontwikkeld om te kunnen analyseren of er sprake is van bias in studiedata in relatie tot het succes van studenten, wat een indicatie kan zijn van een gebrek aan kansengelijkheid. Deze methode gebruikt prognosemodellen op basis van machine learning. Een prognosemodel is dus niet een doel op zich, maar het instrument voor een analyse van kansengelijkheid, ook wel een fairness analyse genoemd.

Over deze methode heeft lector, Dr. Theo Bakker, zijn intreerede uitgesproken op 21 november 2024, getiteld: "[No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning Technology & Analytics.](https://zenodo.org/records/14204674)" (Bakker, 2024).

## Features

- **Complete analyse in één functie** - `analyze_fairness()` voert alle stappen automatisch uit
- **Automatische data transformatie** - Van 1CHO data naar analyse-klaar formaat
- **Machine learning modellen** - Logistic Regression en Random Forest voor prognoses
- **Fairness-metrieken** - Equal Opportunity, Predictive Parity, Accuracy Equality, Statistical Parity
- **Visualisaties** - Automatische generatie van dichtheidsplots en fairness-check plots
- **PDF rapportage** - Professionele rapporten met Quarto
- **Metadata inbegrepen** - Standaard metadata voor directe gebruik
- **Cross-platform** - Werkt op Windows, macOS en Linux

---

## Snel aan de slag

### Installatie

Je kunt het NFWA package direct vanuit GitHub installeren:

```r
# Installeer remotes package als je het nog niet hebt
install.packages("remotes")

# Installeer het NFWA package
remotes::install_github("cedanl/no-fairness-without-awareness")
```

### Vereisten

| Software | Beschrijving | Download |
|----------|--------------|----------|
| **R** | Versie 4.3 of hoger | [Download R](https://cran.r-project.org/) |
| **RStudio** | Aanbevolen IDE (optioneel maar handig) | [Download RStudio](https://posit.co/download/rstudio-desktop/) |
| **Rtools** | Alleen voor Windows - nodig voor package compilatie | [Download Rtools](https://cran.r-project.org/bin/windows/Rtools/) |

### Snelstart: Complete analyse in één functie

```r
library(nfwa)

# Laad je 1CHO data (CSV bestanden met puntkomma separator)
data_ev <- read.csv("pad/naar/jouw_EV_bestand.csv", sep = ";")
data_vakhavw <- read.csv("pad/naar/jouw_VAKHAVW_bestand.csv", sep = ";")

# Voer complete analyse uit
result <- analyze_fairness(
  data_ev = data_ev,
  data_vakhavw = data_vakhavw,
  opleidingsnaam = "Jouw Opleiding",
  eoi = 2020,
  opleidingsvorm = "VT",
  generate_pdf = TRUE
)
```

Dat is alles! De functie voert automatisch alle stappen uit en genereert een PDF rapport in je working directory.

<details>
<summary><b>Stap-voor-stap aanpak</b> (voor meer controle)</summary>

```r
library(nfwa)

# 1. Lees metadata in
metadata <- read_metadata()

# 2. Transformeer je data
df <- transform_data(
  metadata = metadata,
  opleidingsnaam = "Jouw Opleiding",
  opleidingsvorm = "VT",
  eoi = 2020,
  data_ev = data_ev,
  data_vakhavw = data_vakhavw
)

# 3. Voer de fairness-analyse uit
cutoff <- sum(df$retentie) / nrow(df)
run_nfwa(
  df = df,
  df_levels = metadata$df_levels,
  sensitive_variables = metadata$sensitive_variables,
  colors_default = nfwa::colors_default,
  colors_list = nfwa::colors_list,
  cutoff = cutoff
)

# 4. Genereer PDF rapport
render_report(
  opleidingsnaam = "Jouw Opleiding",
  opleidingsvorm = "VT"
)
```
</details>

Resultaten verschijnen in de `temp/` map:
- `fairness_density_{variabele}.png` - Dichtheidsplots
- `fairness_plot_{variabele}.png` - Fairness-check plots
- `conclusions_list.rds` - Tekstuele conclusies
- `result_table.png` - Samenvattende resultatentabel

**Tijdelijke bestanden opruimen:**
```r
# Na het genereren van je PDF rapport:
cleanup_temp()

# Of automatisch tijdens render:
render_report(
  opleidingsnaam = "Jouw Opleiding",
  opleidingsvorm = "VT",
  cleanup_temp = TRUE
)
```

### Data Vereisten

**Aanbevolen:** Gebruik het [1cijferho project](https://github.com/cedanl/1cijferho) om je data voor te bereiden. Dit project converteert 1CHO data naar het juiste formaat voor NFWA analyse.

De output van 1cijferho is direct te gebruiken als input voor NFWA. Je data moet de volgende structuur hebben:

**data_ev** (EV-bestand, studentniveau):
- 1CHO inschrijvingsgegevens per student
- Retentie-indicator
- Persoonsgebonden nummer (student-ID)
- Gevoelige variabelen (geslacht, vooropleiding, etc.)

**data_vakhavw** (VAKHAVW-bestand, vakniveau):
- 1CHO vakcijfers per student
- Gekoppeld aan student-ID via persoonsgebonden nummer

**Data formaat:** CSV bestanden met puntkomma (`;`) als separator.

### Metadata

**Het package bevat standaard metadata!** De volgende bestanden worden automatisch meegeleverd bij installatie:
- ✅ `variabelen.xlsx` - Variabele definities
- ✅ `levels.xlsx` - Categorie levels per variabele
- ✅ `APCG_2019.csv` - APCG verrijkingsdata
- ✅ `SES_PC4_2021-2022.csv` - SES verrijkingsdata
- ✅ Decodeertabellen voor vooropleiding en ISAT codes

Je hoeft **geen eigen metadata** aan te leveren - gebruik gewoon `read_metadata()` en het werkt direct!

**Eigen metadata gebruiken (optioneel):**
Als je eigen metadata wilt gebruiken, kun je de functie aanpassen of handmatig bestanden inladen. Zie `?read_metadata` voor details over de verwachte structuur.

---

## Documentatie en hulp

### Package documentatie

```r
# Package overzicht
?nfwa

# Functie-specifieke help
?analyze_fairness
?transform_data
?run_nfwa
?render_report
?cleanup_temp
```

### Vignette

Voor een uitgebreide handleiding met voorbeelden:

```r
# Bekijk de vignette in R
vignette("nfwa")

# Of open in browser
browseVignettes("nfwa")
```

### Belangrijkste functies

| Functie | Beschrijving |
|---------|--------------|
| `analyze_fairness()` | Complete analyse in één functie (AANBEVOLEN) |
| `read_metadata()` | Laad package metadata |
| `transform_data()` | Transformeer ruwe 1CHO data |
| `run_nfwa()` | Voer fairness-analyse uit |
| `render_report()` | Genereer PDF rapport |
| `cleanup_temp()` | Ruim tijdelijke bestanden op |

### Ondersteunende projecten

- **[1cijferho](https://github.com/cedanl/1cijferho)** - Data voorbereiding: converteert 1CHO bestanden naar het juiste formaat voor NFWA

### Bijdragen en issues

- GitHub repository: [cedanl/no-fairness-without-awareness](https://github.com/cedanl/no-fairness-without-awareness)
- Issues en bugs: [GitHub Issues](https://github.com/cedanl/no-fairness-without-awareness/issues)
- Pull requests zijn welkom!

### Licentie

Dit project is gelicenseerd onder de voorwaarden van de licentie zoals gespecificeerd in het LICENSE bestand.

### Referenties

Bakker, T. (2024). *No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs.* Intreerede lectoraat Learning Technology & Analytics. https://doi.org/10.5281/zenodo.14204674

### Contact

Lectoraat Learning Technology & Analytics
De Haagse Hogeschool
Web: http://www.hhs.nl
