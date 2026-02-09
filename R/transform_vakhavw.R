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

#' Transformeer HAVO/VWO-vakcijfers naar breed formaat
#'
#' Verwerkt ruwe vakcijferdata: selecteert relevante kolommen, berekent
#' de hoogste cijfers per student en vak, pivotteert naar breed formaat
#' (vakken als kolommen) en berekent een gemiddeld wiskundecijfer.
#'
#' @param df Data frame met vakcijfergegevens. Moet de kolommen
#'   `persoonsgebonden_nummer`, `afkorting_vak`,
#'   `cijfer_eerste_centraal_examen`, `gemiddeld_cijfer_cijferlijst` en
#'   `cijfer_schoolexamen` bevatten.
#'
#' @return Een data frame in breed formaat met per student een rij,
#'   vakken als kolommen (centraal examencijfer) en een berekende
#'   kolom `wis` (gemiddeld wiskundecijfer).
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr select group_by summarize ungroup mutate across
#'   starts_with
#' @importFrom tidyr pivot_wider
#' @export
transform_vakhavw <- function(df) {
  
  df |>
    ## Clean names
    janitor::clean_names() |>
    
    ## Select relevant variables
    select(
      persoonsgebonden_nummer,
      afkorting_vak,
      cijfer_eerste_centraal_examen,
      gemiddeld_cijfer_cijferlijst,
      cijfer_schoolexamen
    ) |>
    
    ## Group by student, course and graduation year (pre-education)
    group_by(persoonsgebonden_nummer, afkorting_vak) |>
    
    ## Select only the highest grades
    summarize(
      cijfer_eerste_centraal_examen = max(cijfer_eerste_centraal_examen, na.rm = TRUE),
      gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE),
      cijfer_schoolexamen = mean(cijfer_schoolexamen, na.rm = TRUE)
    ) |>
    
    ungroup() |>
    
    group_by(persoonsgebonden_nummer) |>
    
    ## Select only the highest average grade per student
    mutate(gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE),
           cijfer_schoolexamen = mean(cijfer_schoolexamen, na.rm = TRUE)) |>
    
    ungroup() |>
    
    ## Pivot wider such that we get courses in columns
    tidyr::pivot_wider(names_from = afkorting_vak,
                       values_from = c(cijfer_eerste_centraal_examen)) |>
    
    ## Create wis
    mutate(wis = rowSums(across(starts_with("wis")), na.rm = TRUE) /
             rowSums(!is.na(across(
               starts_with("wis")
             )))) 
  
  
}
