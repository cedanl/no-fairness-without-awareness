## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## create_explain_lf.R ####
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

library(DALEXtra)

create_explain_lf <- function(last_fit, best_model) {
  
  # Extract the fitted model
  fitted_model <- last_fit |>
    tune::extract_fit_parsnip()
  
  # Extract the workflow
  workflow <- last_fit |>
    tune::extract_workflow()
  
  # Create an explainer
  DALEX::explain(
    model = workflow,
    data = df |> select(-retentie),
    y = as.numeric(df$retentie),
    colorize = TRUE,
    verbose = TRUE,
    label = best_model
  )
  
}



