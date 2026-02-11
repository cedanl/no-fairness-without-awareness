<h1>No Fairness Without Awareness (NFWA) Analyse</h1>

<p>Analyseer de kansengelijkheid van je opleiding</p>

<p><a href="#"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&amp;logoColor=white" alt="Windows"/></a> <a href="#"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&amp;logoColor=F0F0F0" alt="macOS"/></a> <a href="#"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&amp;logoColor=black" alt="Linux"/></a> <img src="https://badgen.net/github/last-commit/cedanl/no-fairness-without-awareness" alt="GitHub Last Commit"/> <img src="https://badgen.net/github/contributors/cedanl/no-fairness-without-awareness" alt="Contributors"/> <img src="https://img.shields.io/github/license/cedanl/no-fairness-without-awareness" alt="GitHub License"/></p>

De No Fairness Without Awareness tool is ontwikkeld op basis van het onderzoek van het lectoraat Learning Technology & Analytics (LTA) van De Haagse Hogeschool. Het LTA heeft tot doel kansengelijkheid voor studenten te verhogen met behulp van learning analytics en inzet van learning technology.

Het lectoraat heeft een onderzoeksmethode ontwikkeld om te kunnen analyseren of er sprake is van bias in studiedata in relatie tot het succes van studenten, wat een indicatie kan zijn van een gebrek aan kansengelijkheid. Deze methode gebruikt prognosemodellen op basis van machine learning. Een prognosemodel is dus niet een doel op zich, maar het instrument voor een analyse van kansengelijkheid, ook wel een fairness analyse genoemd.

Over deze methode heeft lector, Dr. Theo Bakker, zijn intreerede uitgesproken op 21 november 2024, getiteld: "[No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning Technology & Analytics.](https://zenodo.org/records/14204674)"(Bakker, 2024).

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

### Gebruik

```r
# Laad het package
library(nfwa)

# 1. Lees metadata in
metadata <- read_metadata()

# 2. Transformeer je data
df <- transform_data(
  metadata = metadata,
  opleidingsnaam = "Jouw Opleiding",
  opleidingsvorm = "VT",
  eoi = 2020,
  df1cho = jouw_1cho_data,
  df1cho_vak = jouw_vak_data
)

# 3. Voer de fairness-analyse uit
run_nfwa(
  df = df,
  df_levels = metadata$df_levels,
  sensitive_variables = metadata$sensitive_variables,
  colors_default = nfwa::colors_default,
  colors_list = nfwa::colors_list,
  cutoff = 0.2
)
```

Resultaten verschijnen in de `output/cache/` map:
- `fairness_density_{variabele}.png` - Dichtheidsplots
- `fairness_plot_{variabele}.png` - Fairness-check plots
- `conclusions_list.rds` - Tekstuele conclusies
- `result_table.png` - Samenvattende resultatentabel

### Data Vereisten

Je data moet de volgende structuur hebben:

**df1cho** (studentniveau):
- Inschrijvingsgegevens per student
- Retentie-indicator
- Persoonsgebonden nummer (student-ID)
- Gevoelige variabelen (geslacht, vooropleiding, etc.)

**df1cho_vak** (vakniveau):
- Vakcijfers per student
- Gekoppeld aan student-ID

### Metadata

Het package heeft metadata nodig voor variabele mapping en levels. Plaats de volgende bestanden in een `metadata/` map:
- `variabelen.xlsx` - Variabele definities
- `levels.xlsx` - Categorie levels per variabele
- Optioneel: APCG en SES data voor verrijking

Zie `?read_metadata` voor meer details.
