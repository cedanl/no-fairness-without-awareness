## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## compare_data.R ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
## Verspreiding buiten De HHs: Nee
##
## Doel: Compare the syntethic
##
## Afhankelijkheden: Afhankelijkheid
##
## Datasets: Datasets
##
## Opmerkingen:
## 1) Geen.
## 2) ___
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Extract ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

df1cho <- arrow::read_parquet(
  fs::path(
    Sys.getenv("LTA_ROOT"),
    "00 LTA Data",
    "1CHO",
    "synthetische data",
    "EV299XX24.parquet"
  )
)


df1cho_vak <- arrow::read_parquet(
  fs::path(
    Sys.getenv("LTA_ROOT"),
    "00 LTA Data",
    "1CHO",
    "synthetische data",
    "VAKHAVW_99XX.parquet"
  )
)

dfsyn <- rio::import("R/data/syn/studyprogrammes_enrollments_syn.rds", trust = TRUE)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

df1cho_vak2 <- df1cho_vak |>
  
  ## Select relevant variables
  select(
    `Persoonsgebonden nummer`,
    `Afkorting vak`,
    `Cijfer eerste centraal examen`,
    `Gemiddeld cijfer cijferlijst`,
    Diplomajaar
  ) |>
  
  ## Group by student, course and graduation year (pre-education)
  group_by(`Persoonsgebonden nummer`, `Afkorting vak`, Diplomajaar) |>
  
  ## Select only the most recent graduation year
  filter(Diplomajaar == max(Diplomajaar)) |>
  
  ## Select only the highest grades
  summarize(
    `Cijfer eerste centraal examen` = max(`Cijfer eerste centraal examen`, na.rm = TRUE),
    `Gemiddeld cijfer cijferlijst` = max(`Gemiddeld cijfer cijferlijst`, na.rm = TRUE),
  ) |>
  ungroup() |>
  
  ## Pivot wider such that we get courses in columns
  pivot_wider(names_from = `Afkorting vak`,
              values_from = c(`Cijfer eerste centraal examen`)) |>
  ## Only select relevant courses
  select(
    `Persoonsgebonden nummer`,
    en,
    entl,
    enzl,
    nat,
    ne,
    netl,
    nezl,
    wisA,
    wisB,
    wisC,
    `Gemiddeld cijfer cijferlijst`,
    Diplomajaar
  )


df1cho_samen <- df1cho |>
  inner_join(
    df1cho_vak2,
    by = c("Persoonsgebonden nummer" = "Persoonsgebonden nummer"),
    relationship = "many-to-many"
  )
