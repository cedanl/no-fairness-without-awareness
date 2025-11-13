## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## transform_1cho_data.R ####
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

transform_1cho_data <- function(df, df_vak) {

  
  df <- df |>
    inner_join(
      df_vak,
      by = c("persoonsgebonden_nummer" = "persoonsgebonden_nummer"),
      relationship = "many-to-one"
    )
  
  df <- df |>
    
    mutate(across(starts_with("datum"), ~as.Date(as.character(.x), format = "%Y%m%d"))) |>
    
    # Convert character variables to factor
    mutate(across(where(is.character), as.factor)) |>
    
    # Convert logical variables to 0 or 1
    mutate(across(where(is.logical), as.integer)) |>
    
    ## Create variable dagen_tussen_inschrijving_1_september
    mutate(dagen_tussen_inschrijving_1_september = as.integer(datum_inschrijving - as.Date(paste0(inschrijvingsjaar, "0901"), format = "%Y%m%d"))) |>
    
    ## Specifically make Retention factor
    mutate(retentie = factor(retentie))
  
  df
  
}
