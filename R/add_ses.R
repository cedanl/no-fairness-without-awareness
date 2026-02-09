## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## add_ses.R ####
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

#' Voeg SES-data toe aan een dataset
#'
#' Koppelt sociaaleconomische status (SES) gegevens van het CBS aan een
#' studentdataset op basis van 4-cijferig postcodegebied. Per postcode wordt
#' het meest recente verslagjaar geselecteerd.
#'
#' @param df Data frame met studentgegevens. Moet de kolom
#'   `postcodecijfers_student_op_1_oktober` bevatten.
#' @param dfses Data frame met SES-gegevens per postcode. Moet de kolommen
#'   `ses_pc4` en `ses_verslagjaar` bevatten.
#'
#' @return Een data frame met dezelfde structuur als `df`, aangevuld met
#'   SES-kolommen en `postcodecijfers_student_op_1_oktober` als integer.
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr left_join mutate across group_by slice_max ungroup
#' @export
add_ses <- function(df, dfses) {
  
  dfses <- dfses |>
    
    janitor::clean_names() |>
    
    ## Remove doubles and choose only one year (2022)
    group_by(ses_pc4) |>
    
    slice_max(ses_verslagjaar) |>
    
    ungroup() 
  
  df <- df |>
    
    left_join(dfses, by = c("postcodecijfers_student_op_1_oktober" = "ses_pc4")) |>
    
    ## Make postcode integer
    mutate(across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))
  
  ## Fill in NA with mean
  
    
}
