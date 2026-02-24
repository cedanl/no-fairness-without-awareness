## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 03_run_nfwa.R ####
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

#' Voer de volledige NFWA fairness-analyse uit
#'
#' Hoofdfunctie die de complete No Fairness Without Awareness (NFWA)
#' analyse-pipeline uitvoert: traint classificatiemodellen, maakt een
#' DALEX-explainer, voert fairness-checks uit per sensitieve variabele,
#' genereert dichtheids- en fairness-plots, en produceert een
#' samenvattende flextable met conclusies.
#'
#' Deze functie schrijft bestanden naar een tijdelijke map (\code{temp/}) in
#' de huidige working directory. Gebruik \code{\link{cleanup_temp}} om deze
#' bestanden te verwijderen na het genereren van het rapport.
#'
#' @param df Data frame met de analyse-data. Moet de kolom `retentie`
#'   en alle sensitieve variabelen bevatten.
#' @param df_levels Data frame met level-definities per variabele,
#'   zoals geretourneerd in `metadata$df_levels`.
#' @param sensitive_variables Character vector met namen van sensitieve
#'   variabelen om te analyseren.
#' @param cutoff Numeriek. Cutoff-waarde voor de fairness-check.
#'   Standaard `0.2`.
#' @param caption Character of `NULL`. Optioneel onderschrift voor
#'   plots.
#'
#' @return Onzichtbaar. Slaat de volgende bestanden op:
#'   \describe{
#'     \item{temp/fairness_density_\{var\}.png}{Dichtheidsplot per
#'       variabele.}
#'     \item{temp/fairness_plot_\{var\}.png}{Fairness-check plot per
#'       variabele.}
#'     \item{temp/conclusions_list.rds}{List met tekstuele
#'       conclusies per variabele.}
#'     \item{temp/result_table.png}{Afbeelding van de
#'       fairness-resultatentabel.}
#'   }
#'
#' @importFrom dplyr mutate across if_else case_when select
#' @importFrom flextable flextable save_as_image
#' @export
run_nfwa <- function(df,
                     df_levels,
                     sensitive_variables,
                     cutoff = 0.2,
                     caption = NULL) {


  ## . ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ## Model Trainen ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  # Make retentie numeric / binary as character
  df <- df |>
    dplyr::mutate(dplyr::across(retentie, ~ dplyr::if_else(. == 0, "0", "1")))

  output     <- run_models(df)
  last_fit   <- output$last_fit
  best_model <- output$best_model

  ## . ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ## Create Explain LF ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  explainer <- create_explain_lf(df, last_fit, best_model)

  ## . ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ## Analyses ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  df_fairness_list <- list()
  
  for (i in seq_along(sensitive_variables)) {
    var <- sensitive_variables[i]
    
    # Privileged group = most common subgroup
    privileged <- get_largest_group(df, var)
    
    # Fairness object
    fairness_object <- get_obj_fairness(
      df          = df,
      explainer   = explainer,
      var   = var,
      privileged  = privileged,
      cutoff      = cutoff
    )
    
    n_categories <- length(unique(df[[var]])) - 1
    
    ## . ####
    ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ## Create density plot ####
    ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    
    # Density plot
    density_plot <- create_density_plot(
      fairness_object,
      group          = var,
      caption        = caption,
      colors_default = colors_default,
      colors_list    = colors_list,
      n_categories = n_categories
    )
  
    ## . ####
    ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    ## Create Fairness plot ####
    ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    
    
    # Fairness plot
    fairness_plot <- suppressWarnings(
      create_fairness_plot(
        fairness_object,
        group      = var,
        privileged = privileged,
        colors_default = colors_default,
        n_categories = n_categories
      ) 
        )
    
    # Fairness check data
    df_fairness_check_data <- get_df_fairness_check_data(df, fairness_object[["fairness_check_data"]], var)
    
    df_fairness_list[[i]] <- df_fairness_check_data |>
      dplyr::mutate(
        FRN_Bias = dplyr::case_when(
          FRN_Score < 0.8  ~ "Negatieve Bias",
          FRN_Score > 1.25 ~ "Positieve Bias",
          TRUE         ~ "Geen Bias"
        )
      )
  }
  
  ## . ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ## Create Flextable ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  df_fairness_wide <- get_df_fairness_wide(df_fairness_list, df, df_levels, sensitive_variables)

  # Now create a text per variable from the table
  conclusions_list <- list()
  for (i in sensitive_variables) {
    conclusions_list[[i]] <- get_fairness_conclusions(df_fairness_wide, i)
  }

  saveRDS(conclusions_list, file = "temp/conclusions_list.rds")


  ft_fairness <- get_ft_fairness(flextable::flextable(df_fairness_wide |>
                                                        dplyr::select(-c(Groep_label, Text))),
                                 colors_default = colors_default)
  
  flextable::save_as_image(x= ft_fairness, path = "temp/result_table.png")
  
  
}
