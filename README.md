<h1>No Fairness Without Awareness (NFWA)</h1>

<p>R package voor kansengelijkheidsanalyse in het hoger onderwijs</p>

<p><a href="#"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&amp;logoColor=white" alt="Windows"/></a> <a href="#"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&amp;logoColor=F0F0F0" alt="macOS"/></a> <a href="#"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&amp;logoColor=black" alt="Linux"/></a> <img src="https://badgen.net/github/last-commit/cedanl/no-fairness-without-awareness" alt="GitHub Last Commit"/> <img src="https://badgen.net/github/contributors/cedanl/no-fairness-without-awareness" alt="Contributors"/> <img src="https://img.shields.io/github/license/cedanl/no-fairness-without-awareness" alt="GitHub License"/></p>

## Over het package

Het **NFWA** (No Fairness Without Awareness) package is een R package ontwikkeld op basis van het onderzoek van het lectoraat Learning Technology & Analytics (LTA) van De Haagse Hogeschool. Het LTA heeft tot doel kansengelijkheid voor studenten te verhogen met behulp van learning analytics en inzet van learning technology.

Het lectoraat heeft een onderzoeksmethode ontwikkeld om te kunnen analyseren of er sprake is van bias in studiedata in relatie tot het succes van studenten, wat een indicatie kan zijn van een gebrek aan kansengelijkheid. Deze methode gebruikt prognosemodellen op basis van machine learning. Een prognosemodel is dus niet een doel op zich, maar het instrument voor een analyse van kansengelijkheid, ook wel een fairness analyse genoemd.

Over deze methode heeft lector, Dr. Theo Bakker, zijn intreerede uitgesproken op 21 november 2024, getiteld: "[No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning Technology & Analytics.](https://zenodo.org/records/14204674)" (Bakker, 2024).

## Features

- **Complete analyse in één functie** - `analyze_fairness()` voert alle stappen automatisch uit
- **Interactieve webinterface** - `run_app()` opent een Shiny app voor gebruik zonder R-kennis
- **Automatische data transformatie** - Van 1CHO data naar analyse-klaar formaat
- **Machine learning modellen** - Logistic Regression en Random Forest voor prognoses
- **Fairness-metrieken** - Equal Opportunity, Predictive Parity, Accuracy Equality, Statistical Parity
- **Visualisaties** - Automatische generatie van dichtheidsplots en fairness-check plots
- **PDF rapportage** - Professionele rapporten met Quarto
- **Metadata inbegrepen** - Standaard metadata voor directe gebruik
- **Cross-platform** - Werkt op Windows, macOS en Linux
- **Docker-ready** - Eén commando om de Shiny app met MinIO en PostgreSQL te draaien
- **Pluggable storage** - Transparant schakelen tussen lokale bestanden en cloud opslag (S3/MinIO + PostgreSQL)
- **CI/CD** - Geautomatiseerde tests: R-CMD-check, integratietests, test-coverage, Scoop installer

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
| **Quarto** | Vereist voor PDF rapportage | [Download Quarto](https://quarto.org/docs/get-started/) |
| **TinyTeX** | LaTeX distributie voor PDF compilatie | Automatisch via `tinytex::install_tinytex()` |

#### ⚠️ Quarto Installatie

Als je **PDF rapporten** wilt genereren, moet je Quarto installeren:

1. **Download en installeer Quarto** van https://quarto.org/docs/get-started/
2. **Herstart R/RStudio volledig** na installatie
3. **Verificatie:**
   ```r
   quarto::quarto_path()  # Moet een pad naar Quarto returneren, niet NULL
   ```

**Troubleshooting:**
- Als `quarto::quarto_path()` `NULL` returnt, is Quarto niet in je PATH
- Herstart R/RStudio na Quarto installatie
- Op Windows: Zorg dat je account admin rechten had bij de installatie
- Geen Quarto? Zet `generate_pdf = FALSE` in `analyze_fairness()` en voer alleen analyses uit

### Snelstart: Shiny app (geen R-kennis vereist)

Voor beleidsmakers en bestuurders die de analyse willen uitvoeren zonder R te leren:

```r
library(nfwa)

# Installeer de Shiny dependencies indien nodig
install.packages(c("shiny", "bslib"))

# Open de webinterface
run_app()
```

De app opent in je browser. Upload je EV en VAKHAVW bestanden, selecteer de opleiding en het instroomcohort, en download het PDF rapport.

### Snelstart: Complete analyse in één functie

```r
library(nfwa)

# Laad je 1CHO data (CSV bestanden met puntkomma separator)
data_ev <- read.csv("pad/naar/jouw_EV_bestand.csv", sep = ";")
data_vakhavw <- read.csv("pad/naar/jouw_VAKHAVW_bestand.csv", sep = ";")

# Voer complete analyse uit
# eoi = minimaal instroomcohort (studenten die in 2020 of later zijn gestart)
result <- analyze_fairness(
  data_ev = data_ev,
  data_vakhavw = data_vakhavw,
  opleidingsnaam = "B Tandheelkunde",
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
  opleidingsnaam = "B Tandheelkunde",
  opleidingsvorm = "VT",
  eoi = 2020,  # studenten vanaf cohort 2020
  data_ev = data_ev,
  data_vakhavw = data_vakhavw
)

# 3. Voer de fairness-analyse uit
cutoff <- sum(df$retentie) / nrow(df)
run_nfwa(
  df = df,
  df_levels = metadata$df_levels,
  sensitive_variables = metadata$sensitive_variables,
  cutoff = cutoff
)

# 4. Genereer PDF rapport
render_report(
  opleidingsnaam = "B Tandheelkunde",
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
  opleidingsnaam = "B Tandheelkunde",
  opleidingsvorm = "VT",
  cleanup_temp = TRUE
)
```

### Data Vereisten

Dit package werkt met **enriched** 1CHO data. Dat zijn de bestanden die eindigen op `_enriched.csv`, gegenereerd door de [1CijferHO Tool](https://github.com/cedanl/1cijferho).

#### Stap 1: Data voorbereiden met 1CijferHO

Gebruik de [1CijferHO Tool](https://github.com/cedanl/1cijferho) om je ruwe 1CHO bestanden om te zetten naar enriched CSV's. De tool draait de volledige pipeline voor je:

```bash
eencijferho pipeline --input data/01-input --output data/02-output
```

Dit levert onder andere op:
- `EV*_enriched.csv` -- inschrijvingsgegevens met gedecodeerde velden
- `VAKHAVW*_enriched.csv` -- vakcijfers

De enriched bestanden bevatten leesbare namen in plaats van codes, bijvoorbeeld opleidingsnamen (`opleidingscode_naam_opleiding`) en vooropleiding-omschrijvingen. NFWA heeft deze gedecodeerde kolommen nodig om te werken.

> Gebruik dus altijd de `_enriched.csv` bestanden, niet de `_decoded.csv` of de gewone `.csv` output.

#### Stap 2: Data inladen in R

```r
data_ev <- read.csv("pad/naar/EV_enriched.csv", sep = ";")
data_vakhavw <- read.csv("pad/naar/VAKHAVW_enriched.csv", sep = ";")
```

#### Verwachte bestanden

**data_ev** (EV-bestand, studentniveau):
- Inschrijvingsgegevens per student
- Gedecodeerde opleidingsnamen (`opleidingscode_naam_opleiding`)
- Gedecodeerde vooropleiding-omschrijvingen
- Persoonsgebonden nummer, geslacht, postcode, etc.

**data_vakhavw** (VAKHAVW-bestand, vakniveau):
- Vakcijfers per student (centraal examen, schoolexamen)
- Gekoppeld via persoonsgebonden nummer

**Data formaat:** CSV bestanden met puntkomma (`;`) als separator.

### Metadata

Het package bevat standaard metadata (variabelen, levels, APCG en SES data). Je hoeft geen eigen metadata aan te leveren -- `read_metadata()` laadt alles automatisch.

---

## Docker

De Shiny app kan met Docker Compose gedraaid worden, inclusief MinIO (S3-compatibele objectopslag) en PostgreSQL:

```bash
docker compose up -d
```

Dit start drie services:

| Service | Poort | Beschrijving |
|---------|-------|--------------|
| **shiny** | [localhost:3838](http://localhost:3838) | NFWA Shiny webinterface |
| **minio** | [localhost:9001](http://localhost:9001) | MinIO console (user: `minioadmin`, ww: `minioadmin`) |
| **postgres** | 5432 | PostgreSQL database |

### Developer GUI tools (optioneel)

pgAdmin (PostgreSQL GUI) is beschikbaar via het `dev` profiel:

```bash
docker compose --profile dev up -d
```

| Service | Poort | Beschrijving |
|---------|-------|--------------|
| **pgadmin** | [localhost:5050](http://localhost:5050) | pgAdmin (email: `admin@nfwa.local`, ww: `admin`) |

Verbind in pgAdmin met host `postgres`, poort `5432`, gebruiker/wachtwoord `nfwa`.

### Lokale poortconflicten

Als poort 9000 op jouw machine bezet is (bijv. door een VPN-client), maak dan een lokaal bestand `docker-compose.override.yml` aan (staat in `.gitignore`):

```yaml
services:
  minio:
    ports:
      - "9002:9000"
      - "9003:9001"
  shiny:
    environment:
      NFWA_S3_ENDPOINT: http://minio:9000
```

MinIO is dan bereikbaar op poort 9002 (API) en 9003 (console).

Stoppen en opruimen:

```bash
docker compose down           # stop containers, behoud data
docker compose down -v        # stop containers en verwijder volumes
```

### Image opnieuw bouwen

Na code-wijzigingen:

```bash
docker compose build shiny    # rebuild alleen de Shiny app
docker compose up -d          # herstart met nieuw image
```

---

## Storage backends

Het package ondersteunt twee storage backends, gecontroleerd via de omgevingsvariabele `NFWA_STORAGE_BACKEND`:

### File backend (standaard)

Leest en schrijft naar het lokale bestandssysteem. Geen extra configuratie nodig — dit is het standaardgedrag voor R-gebruikers die lokaal werken.

```r
storage <- nfwa_storage()                     # of expliciet:
storage <- nfwa_storage(backend = "file")
```

### S3 + PostgreSQL backend

Voor Docker- en Kubernetes-deployments. Tabulaire data wordt opgeslagen in PostgreSQL, bestanden (PDF, plots) in S3-compatibele opslag (MinIO of AWS S3).

```r
Sys.setenv(NFWA_STORAGE_BACKEND = "s3pg")
storage <- nfwa_storage()
```

Configuratie via omgevingsvariabelen:

| Variabele | Standaard | Beschrijving |
|-----------|-----------|--------------|
| `NFWA_S3_ENDPOINT` | `http://localhost:9000` | S3/MinIO endpoint |
| `NFWA_S3_BUCKET` | `nfwa` | Bucketnaam |
| `NFWA_S3_REGION` | _(leeg)_ | Regio (leeg voor MinIO, stel in voor AWS S3) |
| `NFWA_S3_ACCESS_KEY` | | Access key |
| `NFWA_S3_SECRET_KEY` | | Secret key |
| `NFWA_PG_HOST` | `localhost` | PostgreSQL host |
| `NFWA_PG_PORT` | `5432` | PostgreSQL poort |
| `NFWA_PG_DBNAME` | `nfwa` | Database naam |
| `NFWA_PG_USER` | `nfwa` | Database gebruiker |
| `NFWA_PG_PASSWORD` | | Database wachtwoord |

De S3+PG backend vereist de packages `aws.s3`, `DBI` en `RPostgres` (staan in Suggests, niet nodig voor lokaal gebruik).

---

## Testen

### Lokaal

```bash
Rscript -e 'testthat::test_local()'                       # alle tests
Rscript -e 'testthat::test_local(filter = "storage")'     # alleen storage tests
```

Of vanuit R/RStudio:

```r
devtools::test()
```

### CI/CD (GitHub Actions)

De repository bevat vier geautomatiseerde workflows:

| Workflow | Beschrijving |
|----------|--------------|
| **R-CMD-check** | Standaard R package check op meerdere platforms |
| **integration-test** | Volledige pipeline met MinIO + PostgreSQL service containers |
| **test-coverage** | Code coverage rapportage |
| **scoop-installer-test** | Windows Scoop manifest validatie |

De integratietest draait de complete analyse-pipeline op twee backends (file en s3pg) en verifieert PDF-generatie.

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
| `run_app()` | Open de Shiny webinterface (geen R-kennis vereist) |
| `analyze_fairness()` | Complete analyse in één functie (AANBEVOLEN) |
| `read_metadata()` | Laad package metadata |
| `transform_data()` | Transformeer ruwe 1CHO data |
| `run_nfwa()` | Voer fairness-analyse uit |
| `render_report()` | Genereer PDF rapport |
| `cleanup_temp()` | Ruim tijdelijke bestanden op |
| `nfwa_storage()` | Maak een storage backend aan (file of s3pg) |

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
