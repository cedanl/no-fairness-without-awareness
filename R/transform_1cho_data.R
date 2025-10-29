## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## mutate_1cho.R ####
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
library(tidylog)

transform_vakhavw <- function(df) {
  df |>
    
    ## Select relevant variables
    select(
      `Persoonsgebonden nummer`,
      `Afkorting vak`,
      `Cijfer cijferlijst`,
      `Gemiddeld cijfer cijferlijst`
    ) |>
    
    ## Group by student, course and graduation year (pre-education)
    group_by(`Persoonsgebonden nummer`, `Afkorting vak`) |>
    
    ## Select only the highest grades
    summarize(
      `Cijfer cijferlijst` = max(`Cijfer cijferlijst`, na.rm = TRUE),
      `Gemiddeld cijfer cijferlijst` = max(`Gemiddeld cijfer cijferlijst`, na.rm = TRUE)
    ) |>
    
    ungroup() |>
    
    group_by(`Persoonsgebonden nummer`) |>
    
    mutate(
      `Gemiddeld cijfer cijferlijst` = max(`Gemiddeld cijfer cijferlijst`, na.rm = TRUE)
    ) |>
    
    ungroup() |>
    
    ## Pivot wider such that we get courses in columns
    tidyr::pivot_wider(names_from = `Afkorting vak`,
                       values_from = c(`Cijfer cijferlijst`)) 
  
}

transform_ev_data <- function(df, opleidingscode, eoi) {
  df |>
    filter(Opleidingscode == opleidingscode,
                  `Eerste jaar aan deze instelling` >= eoi) |>
    
    group_by(`Persoonsgebonden nummer`) |>
    
    mutate(Retentie = any(Inschrijvingsjaar == `Eerste jaar aan deze opleiding-instelling` + 1)) |>
    
    ungroup() |>
    
    filter(Inschrijvingsjaar == `Eerste jaar aan deze opleiding-instelling`) 
  
}

transform_1cho_data <- function(df, df_vak, opleidingscode, eoi) {
  var <- read.csv("metadata/variabelen.csv", sep = ";") |>
    filter(Used) |>
    pull(Variable)
  
  df_vak <- transform_vakhavw(df_vak)
  
  df <- transform_ev_data(df, opleidingscode, eoi)
  
  df <- df |>
    inner_join(
      df_vak,
      by = c("Persoonsgebonden nummer" = "Persoonsgebonden nummer"),
      relationship = "many-to-one"
    )
  
  df <- df |>
    select(all_of(var)) |>
    
    mutate(across(starts_with("Datum"), ~as.Date(as.character(.x), format = "%Y%m%d"))) |>
    
    # Imputate all numeric variables with the mean
    mutate(across(where(is.numeric), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))) |>
    
    # Convert character variables to factor
    mutate(across(where(is.character), as.factor)) |>
    
    # Convert logical variables to 0 or 1
    mutate(across(where(is.logical), as.integer)) |>
    
    ## Specifically make Retention factor
    mutate(Retentie = factor(Retentie))
  
  df
  
}


