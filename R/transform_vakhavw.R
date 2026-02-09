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

transform_vakhavw <- function(df) {

  df |>
    ## Clean names
    janitor::clean_names() |>

    ## Select relevant variables
    dplyr::select(
      persoonsgebonden_nummer,
      afkorting_vak,
      cijfer_eerste_centraal_examen,
      gemiddeld_cijfer_cijferlijst,
      cijfer_schoolexamen
    ) |>

    ## Group by student, course and graduation year (pre-education)
    dplyr::group_by(persoonsgebonden_nummer, afkorting_vak) |>

    ## Select only the highest grades
    dplyr::summarize(
      cijfer_eerste_centraal_examen = max(cijfer_eerste_centraal_examen, na.rm = TRUE),
      gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE),
      cijfer_schoolexamen = mean(cijfer_schoolexamen, na.rm = TRUE)
    ) |>

    dplyr::ungroup() |>

    dplyr::group_by(persoonsgebonden_nummer) |>

    ## Select only the highest average grade per student
    dplyr::mutate(gemiddeld_cijfer_cijferlijst = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE),
           cijfer_schoolexamen = mean(cijfer_schoolexamen, na.rm = TRUE)) |>

    dplyr::ungroup() |>

    ## Pivot wider such that we get courses in columns
    tidyr::pivot_wider(names_from = afkorting_vak,
                       values_from = c(cijfer_eerste_centraal_examen)) |>

    ## Create wis
    dplyr::mutate(wis = rowSums(dplyr::across(dplyr::starts_with("wis")), na.rm = TRUE) /
             rowSums(!is.na(dplyr::across(
               dplyr::starts_with("wis")
             )))) 
  
  
}
