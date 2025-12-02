## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## render.R ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
## Verspreiding buiten De HHs: Nee
##
## Doel: Doel
##
## Afhankelijkheden: Afhankelijkheid
##
## Datasets: Datasets
##
## Opmerkingen:
## 1) Geen.
## 2) ___
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


source("scripts/main.R")

cfg <- config::get()

quarto::quarto_render(
  input = "scripts/main.qmd",
  output_file = paste0(
    "kansengelijkheidanalysis_",
    gsub(" ", "_", tolower(cfg$opleidingsnaam)),
    "_",
    cfg$opleidingsvorm,
    ".pdf"
  ),
  execute_params = list(
    title = paste0(
      "De uitkomsten van de kansengelijkheidanalysis voor ",
      cfg$opleidingsnaam,
      " ",
      cfg$opleidingsvorm
    )
  )
)
