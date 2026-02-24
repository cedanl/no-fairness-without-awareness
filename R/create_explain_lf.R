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


#' Maak een DALEX-explainer van een afgerond model
#'
#' Extraheert het getrainde model en de workflow uit een `last_fit`-object
#' en maakt een DALEX-explainer aan waarmee fairness-analyses kunnen worden
#' uitgevoerd.
#'
#' @param df Verwerkte 1CHO en 1CHO vak data uit NFWA package
#'   
#' @param last_fit Een `last_fit`-object uit het tidymodels-framework, met
#'   daarin het getrainde model en de bijbehorende workflow.
#' @param best_model Character. Naam van het beste model, gebruikt als label
#'   voor de explainer (bijv. `"Logistic Regression"`).
#'
#' @return Een [DALEX::explain()]-object dat kan worden gebruikt voor
#'   fairness-checks en model-interpretatie.
#'
#' @importFrom DALEXtra explain_tidymodels
#' @importFrom DALEX explain
#' @importFrom tune extract_fit_parsnip extract_workflow
#' @keywords internal
create_explain_lf <- function(df, last_fit, best_model) {

  # Extract the fitted model
  fitted_model <- last_fit |>
    tune::extract_fit_parsnip()

  # Extract the workflow
  workflow <- last_fit |>
    tune::extract_workflow()

  # Create an explainer
  DALEX::explain(
    model = fitted_model,
    data = df |> dplyr::select(-retentie),
    y = as.numeric(df$retentie),
    colorize = FALSE,
    verbose = FALSE,
    label = best_model,
    type = "classification"
  )

}



