<h1>No Fairness Without Awareness (NFWA) Analyse</h1>

<p>Analyseer de kansengelijkheid van je opleiding</p>

<p><a href="#"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&amp;logoColor=white" alt="Windows"/></a> <a href="#"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&amp;logoColor=F0F0F0" alt="macOS"/></a> <a href="#"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&amp;logoColor=black" alt="Linux"/></a> <img src="https://badgen.net/github/last-commit/cedanl/no-fairness-without-awareness" alt="GitHub Last Commit"/> <img src="https://badgen.net/github/contributors/cedanl/no-fairness-without-awareness" alt="Contributors"/> <img src="https://img.shields.io/github/license/cedanl/no-fairness-without-awareness" alt="GitHub License"/></p>

De No Fairness Without Awareness tool is ontwikkeld op basis van het onderzoek van het lectoraat Learning Technology & Analytics (LTA) van De Haagse Hogeschool. Het LTA heeft tot doel kansengelijkheid voor studenten te verhogen met behulp van learning analytics en inzet van learning technology.

Het lectoraat heeft een onderzoeksmethode ontwikkeld om te kunnen analyseren of er sprake is van bias in studiedata in relatie tot het succes van studenten, wat een indicatie kan zijn van een gebrek aan kansengelijkheid. Deze methode gebruikt prognosemodellen op basis van machine learning. Een prognosemodel is dus niet een doel op zich, maar het instrument voor een analyse van kansengelijkheid, ook wel een fairness analyse genoemd.

Over deze methode heeft lector, Dr. Theo Bakker, zijn intreerede uitgesproken op 21 november 2024, getiteld: "[No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning Technology & Analytics.](https://zenodo.org/records/14204674)"(Bakker, 2024).

---

## Snel aan de slag

Voor gebruikers die het project gewoon willen uitvoeren, volg deze eenvoudige stappen:

### Stap 1: Installeer de benodigde software

| Software | Beschrijving | Download |
|----------|--------------|----------|
| **R** | Versie 4.3 of hoger | [Download R](https://cran.r-project.org/) |
| **RStudio** | Aanbevolen IDE (optioneel maar handig) | [Download RStudio](https://posit.co/download/rstudio-desktop/) |
| **Quarto** | Voor het genereren van PDF-rapporten | [Download Quarto](https://quarto.org/docs/get-started/) |
| **LaTeX** | Voor PDF-uitvoer (TinyTeX of TeX Live) | Zie instructies hieronder |
| **Rtools** | Alleen voor Windows - nodig voor package compilatie | [Download Rtools](https://cran.r-project.org/bin/windows/Rtools/) |

#### LaTeX installeren

**Optie 1: TinyTeX (aanbevolen - eenvoudigst)**
```r
# Voer dit uit in R/RStudio
install.packages("tinytex")
tinytex::install_tinytex()
```

**Optie 2: TeX Live**
- Windows: Download van [tug.org/texlive](https://tug.org/texlive/)
- macOS: `brew install --cask mactex` of download [MacTeX](https://www.tug.org/mactex/)
- Linux: `sudo apt install texlive-full` (Ubuntu/Debian)

### Stap 2: Download het project

```bash
git clone https://github.com/cedanl/no-fairness-without-awareness.git
cd no-fairness-without-awareness
```

Of download als ZIP via GitHub en pak uit.

### Stap 3: Installeer R-packages

Open het project in RStudio of navigeer naar de projectmap in R en voer uit:

```r
# Installeer renv als je het nog niet hebt
install.packages("renv")

# Herstel alle project-packages
renv::restore()
```

Dit installeert automatisch alle benodigde packages in de juiste versies.

### Stap 4: Voeg je data toe

Plaats je databestanden (Parquet of CSV) in data/input:
- `df1cho` - studentniveau data (instroom/retentie basis)
- `df1cho_vak` - vakniveau data

Pas de paden aan in `main.R` naar de locatie van je bestanden.

### Stap 5: Voer de analyse uit

```r
source("main.R")
```

Resultaten verschijnen in de `output/` map, inclusief een PDF-rapport.
