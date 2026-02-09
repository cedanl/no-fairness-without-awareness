## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## run_models.R ####
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

library(tidymodels)
library(glmnet)
library(knitr)

#' Train en evalueer classificatiemodellen voor retentievoorspelling
#'
#' Traint een logistisch regressiemodel (met LASSO-regularisatie) en een
#' random forest-model op de data, evalueert beide op AUC/ROC en geeft
#' het beste model terug. De data wordt gesplitst in 60% training, 20%
#' validatie en 20% test.
#'
#' @param df Data frame met de modeldata. Moet de kolom `retentie`
#'   (uitkomstvariabele), `persoonsgebonden_nummer` (student-ID) en
#'   `inschrijvingsjaar` bevatten.
#'
#' @return Een list met twee elementen:
#'   \describe{
#'     \item{last_fit}{Het `last_fit`-object van het beste model.}
#'     \item{best_model}{Character. Naam van het beste model
#'       (`"Logistic Regression"` of `"Random Forest"`).}
#'   }
#'
#' @importFrom tidymodels initial_validation_split training testing
#'   validation_set vfold_cv logistic_reg rand_forest workflow add_model
#'   add_recipe recipe update_role step_rm step_dummy step_zv
#'   step_normalize tune_grid control_grid metric_set roc_auc
#'   collect_metrics collect_predictions select_best last_fit
#' @importFrom glmnet glmnet
#' @export
run_models <- function(df) {
  df_model_results <- data.frame(model = character(), auc = numeric())
  
  # Split the data into 3 parts: 60%, 20% and 20%
  set.seed(100)
  splits      <- initial_validation_split(df, strata = retentie, prop = c(0.6, 0.2))
  
  # Create three sets: a training set, a test set and a validation set
  df_train      <- training(splits)
  df_test       <- testing(splits)
  df_validation <- validation_set(splits)
  
  # Create a resample set based on 10 folds (default)
  df_resamples  <- vfold_cv(df_train, strata = retentie)
  
  # Build the model: logistic regression
  lr_mod <-
    logistic_reg(penalty = tune(), mixture = 1) |>
    set_engine("glmnet")
  
  
  # Build the recipe: logistic regression
  lr_recipe <-
    recipe(retentie ~ ., data = df_train) |>
    update_role(persoonsgebonden_nummer, new_role = "ID") |>           # Set the student ID as an ID variable
    step_rm(persoonsgebonden_nummer, inschrijvingsjaar) |>                   # Remove ID and college year from the model
    # step_unknown(Studiekeuzeprofiel, new_level = "Onbekend skp") |>   # Add unknown skp
    step_dummy(all_nominal_predictors()) |>       # Create dummy variables from categorical variables
    step_zv(all_predictors()) |>                  # Remove zero values
    step_normalize(all_numeric_predictors())      # Center and scale numeric variables
  
  
  # Create the workflow: logistic regression
  lr_workflow <-
    workflow() |>         # Create a workflow
    add_model(lr_mod) |>  # Add the model
    add_recipe(lr_recipe) # Add the recipe
  
  # Create a grid: logistic regression
  lr_reg_grid <- tibble(penalty = 10^seq(-4, -1, length.out = 30))
  
  # Train and tune the model: logistic regression
  lr_res <-
    lr_workflow |>
    tune_grid(
      df_validation,
      grid = lr_reg_grid,
      control = control_grid(save_pred = TRUE),
      metrics = metric_set(roc_auc)
    )
  
  # Select the best model: logistic regression
  lr_best <-
    lr_res |>
    collect_metrics() |>
    filter(mean == max(mean)) |>
    slice(1)
  
  
  # Collect the predictions and evaluate the model (AUC/ROC): logistic regression
  lr_auc <-
    lr_res |>
    collect_predictions(parameters = lr_best) |>
    roc_curve(retentie, .pred_0) |>
    mutate(model = "Logistisch Regressie")
  
  # Determine the AUC of the best model
  lr_auc_highest   <-
    lr_res |>
    collect_predictions(parameters = lr_best) |>
    roc_auc(retentie, .pred_0)
  
  # Add model name and AUC df_model_results
  df_model_results <-
    df_model_results |>
    add_row(model = "Logistic Regression", auc = lr_auc_highest$.estimate)
  
  # Determine the number of cores
  cores <- parallel::detectCores()
  
  # Build the model: random forest
  
  rf_mod <-
    rand_forest(mtry = tune(),
                min_n = tune(),
                trees = 1000) |>
    set_engine("ranger", num.threads = cores) |>
    set_mode("classification")
  
  # Create the recipe: random forest
  rf_recipe <-
    recipe(retentie ~ ., data = df_train) |>
    # step_unknown(Studiekeuzeprofiel, new_level = "Onbekend skp") |>   # Add unknown skp
    step_rm(persoonsgebonden_nummer, inschrijvingsjaar)
  
  # Create the workflow: random forest
  rf_workflow <-
    workflow() |>
    add_model(rf_mod) |>
    add_recipe(rf_recipe)
  
  # Show the parameters that can be tuned
  rf_mod
  
  # Extract the parameters being tuned
  extract_parameter_set_dials(rf_mod)
  
  # Build the grid: random forest
  rf_res <-
    rf_workflow |>
    tune_grid(
      df_validation,
      grid = 25,
      control = control_grid(save_pred = TRUE),
      metrics = metric_set(roc_auc)
    )
  
  # Show the best models
  rf_res |>
    show_best(metric = "roc_auc", n = 15) |>
    mutate(mean = round(mean, 6)) |>
    knitr::kable(
      col.names = c(
        "Mtry",
        "Min. aantal",
        "Metriek",
        "Estimator",
        "Gemiddelde",
        "Aantal",
        "SE",
        "Configuratie"
      )
    )
  
  # Select the best model
  rf_best <-
    rf_res |>
    select_best(metric = "roc_auc")
  
  # Determine the AUC/ROC curve
  rf_auc <-
    rf_res |>
    collect_predictions(parameters = rf_best) |>
    roc_curve(retentie, .pred_0) |>
    mutate(model = "Random Forest")
  
  # Determine the AUC of the best model
  rf_auc_highest   <-
    rf_res |>
    collect_predictions(parameters = rf_best) |>
    roc_auc(retentie, .pred_0)
  
  # Add model name and AUC to df_model_results
  df_model_results <-
    df_model_results |>
    add_row(model = "Random Forest", auc = rf_auc_highest$.estimate)
  
  last_rf_mod <-
    rand_forest(mtry = rf_best$mtry,
                min_n = rf_best$min_n,
                trees = 1000) |>
    set_engine("ranger", num.threads = cores, importance = "impurity") |>
    set_mode("classification")
  
  last_rf_workflow <-
    rf_workflow |>
    update_model(last_rf_mod)
  
  last_fit_rf <-
    last_rf_workflow |>
    last_fit(splits)
  
  
  # Determine which of the models is best based on highest AUC/ROC
  df_model_results <- df_model_results |>
    mutate(number = row_number()) |>
    mutate(best = ifelse(auc == max(auc), TRUE, FALSE)) |>
    arrange(number)
  
  # Determine the best model
  best_model     <- df_model_results$model[df_model_results$best == TRUE][1]
  best_model_auc <- round(df_model_results$auc[df_model_results$best == TRUE], 4)[1]
  
  # Build the final models
  last_lr_mod <-
    logistic_reg(penalty = lr_best$penalty, mixture = 1) |>
    set_engine("glmnet") |>
    set_mode("classification")
  
  # Update the workflows
  last_lr_workflow <-
    lr_workflow |>
    update_model(last_lr_mod)
  
  # Make a final fit for both models so we can save it for later use
  last_fit_lr <-
    last_lr_workflow |>
    last_fit(splits)
  
  last_fit_rf <-
    last_rf_workflow |>
    last_fit(splits)
  
  last_fits <- list(last_fit_lr, last_fit_rf) |>
    set_names(c("Logistic Regression", "Random Forest"))
  
  # Determine which model is best
  if (best_model == "Logistic Regression") {
    last_fit <- last_fit_lr
  } else if (best_model == "Random Forest") {
    last_fit <- last_fit_rf
  }
  
  list(last_fit = last_fit, best_model = best_model)
  
}
