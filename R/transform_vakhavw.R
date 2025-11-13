## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## transform_vakhavw.R ####
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

library(dplyr)

transform_vakhavw <- function(df) {
  df |>
    ## Clean names
    janitor::clean_names() |>
    
    ## Select relevant variables
    select(
      persoonsgebonden_nummer,
      afkorting_vak,
      cijfer_cijferlijst,
      gemiddeld_cijfer_cijferlijst
    ) |>
    
    ## Group by student, course and graduation year (pre-education)
    group_by(persoonsgebonden_nummer, afkorting_vak) |>
    
    ## Select only the highest grades
    summarize(
      cijfer_cijferlijst = max(cijfer_cijferlijst, na.rm = TRUE),
      gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE)
    ) |>
    
    ungroup() |>
    
    group_by(persoonsgebonden_nummer) |>
    
    mutate(
      gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE)
    ) |>
    
    ungroup() |>
    
    ## Pivot wider such that we get courses in columns
    tidyr::pivot_wider(names_from = afkorting_vak,
                       values_from = c(cijfer_cijferlijst)) 
  
}
