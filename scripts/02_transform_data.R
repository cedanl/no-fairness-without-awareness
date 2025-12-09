## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 02_transform_data.R ####
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

transform_data <- function(metadata, 
                           opleidingsnaam,
                           opleidingsvorm,
                           eoi,
                           df1cho,
                           df1cho_vak) {
  
  dfapcg <- metadata$dfapcg
  dfses <- metadata$dfses
  variables <- metadata$variables
  dec_vopl <- metadata$dec_vopl
  dec_isat <- metadata$dec_isat
  
  
  #-------------------------------------------------------------------
  # Transform
  #-------------------------------------------------------------------
  source("R/transform_ev_data.R")
  df1cho2 <- transform_ev_data(
    df1cho,
    naam = opleidingsnaam,
    eoi  = eoi,
    vorm = opleidingsvorm,
    dec_vopl = dec_vopl,
    dec_isat = dec_isat
  )
  
  source("R/transform_vakhavw.R")
  df1cho_vak2 <- transform_vakhavw(df1cho_vak)
  
  source("R/transform_1cho_data.R")
  dfcyfer <- transform_1cho_data(df1cho2, df1cho_vak2)
  
  #-------------------------------------------------------------------
  # Add APCG & SES + basic cleaning
  #-------------------------------------------------------------------
  source("R/add_apcg.R")
  source("R/add_ses.R")
  
  df <- dfcyfer |>
    add_apcg(dfapcg) |>
    add_ses(dfses) |>
    # Select variables used in the model
    dplyr::select(dplyr::all_of(variables)) |>
    # Impute all numeric variables with the mean
    dplyr::mutate(dplyr::across(where(is.numeric), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x)))
  
  return(df)
}
