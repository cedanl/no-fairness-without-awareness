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

run_models <- function(df) {
  df_model_results <- data.frame(model = character(), auc = numeric())

  # Split the data into 3 parts: 60%, 20% and 20%
  set.seed(100)
  splits      <- rsample::initial_validation_split(df, strata = retentie, prop = c(0.6, 0.2))

  # Create three sets: a training set, a test set and a validation set
  df_train      <- rsample::training(splits)
  df_test       <- rsample::testing(splits)
  df_validation <- rsample::validation_set(splits)
  
  # Create a resample set based on 10 folds (default)
  df_resamples  <- rsample::vfold_cv(df_train, strata = retentie)

  # Build the model: logistic regression
  lr_mod <-
    parsnip::logistic_reg(penalty = tune::tune(), mixture = 1) |>
    parsnip::set_engine("glmnet")
  
  
  # Build the recipe: logistic regression
  lr_recipe <-
    recipes::recipe(retentie ~ ., data = df_train) |>
    recipes::update_role(persoonsgebonden_nummer, new_role = "ID") |>           # Set the student ID as an ID variable
    recipes::step_rm(persoonsgebonden_nummer, inschrijvingsjaar) |>                   # Remove ID and college year from the model
    # recipes::step_unknown(Studiekeuzeprofiel, new_level = "Onbekend skp") |>   # Add unknown skp
    recipes::step_dummy(recipes::all_nominal_predictors()) |>       # Create dummy variables from categorical variables
    recipes::step_zv(recipes::all_predictors()) |>                  # Remove zero values
    recipes::step_normalize(recipes::all_numeric_predictors())      # Center and scale numeric variables


  # Create the workflow: logistic regression
  lr_workflow <-
    workflows::workflow() |>         # Create a workflow
    workflows::add_model(lr_mod) |>  # Add the model
    workflows::add_recipe(lr_recipe) # Add the recipe

  # Create a grid: logistic regression
  lr_reg_grid <- tibble::tibble(penalty = 10^seq(-4, -1, length.out = 30))

  # Train and tune the model: logistic regression
  lr_res <-
    lr_workflow |>
    tune::tune_grid(
      df_validation,
      grid = lr_reg_grid,
      control = tune::control_grid(save_pred = TRUE),
      metrics = yardstick::metric_set(yardstick::roc_auc)
    )

  # Select the best model: logistic regression
  lr_best <-
    lr_res |>
    tune::collect_metrics() |>
    dplyr::filter(mean == max(mean)) |>
    dplyr::slice(1)


  # Collect the predictions and evaluate the model (AUC/ROC): logistic regression
  lr_auc <-
    lr_res |>
    tune::collect_predictions(parameters = lr_best) |>
    yardstick::roc_curve(retentie, .pred_0) |>
    dplyr::mutate(model = "Logistisch Regressie")

  # Determine the AUC of the best model
  lr_auc_highest   <-
    lr_res |>
    tune::collect_predictions(parameters = lr_best) |>
    yardstick::roc_auc(retentie, .pred_0)

  # Add model name and AUC df_model_results
  df_model_results <-
    df_model_results |>
    tibble::add_row(model = "Logistic Regression", auc = lr_auc_highest$.estimate)
  
  # Determine the number of cores
  cores <- parallel::detectCores()

  # Build the model: random forest

  rf_mod <-
    parsnip::rand_forest(mtry = tune::tune(),
                min_n = tune::tune(),
                trees = 1000) |>
    parsnip::set_engine("ranger", num.threads = cores) |>
    parsnip::set_mode("classification")

  # Create the recipe: random forest
  rf_recipe <-
    recipes::recipe(retentie ~ ., data = df_train) |>
    # recipes::step_unknown(Studiekeuzeprofiel, new_level = "Onbekend skp") |>   # Add unknown skp
    recipes::step_rm(persoonsgebonden_nummer, inschrijvingsjaar)

  # Create the workflow: random forest
  rf_workflow <-
    workflows::workflow() |>
    workflows::add_model(rf_mod) |>
    workflows::add_recipe(rf_recipe)

  # Show the parameters that can be tuned
  rf_mod

  # Extract the parameters being tuned
  tune::extract_parameter_set_dials(rf_mod)

  # Build the grid: random forest
  rf_res <-
    rf_workflow |>
    tune::tune_grid(
      df_validation,
      grid = 25,
      control = tune::control_grid(save_pred = TRUE),
      metrics = yardstick::metric_set(yardstick::roc_auc)
    )

  # Show the best models
  rf_res |>
    tune::show_best(metric = "roc_auc", n = 15) |>
    dplyr::mutate(mean = round(mean, 6)) |>
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
    tune::select_best(metric = "roc_auc")

  # Determine the AUC/ROC curve
  rf_auc <-
    rf_res |>
    tune::collect_predictions(parameters = rf_best) |>
    yardstick::roc_curve(retentie, .pred_0) |>
    dplyr::mutate(model = "Random Forest")

  # Determine the AUC of the best model
  rf_auc_highest   <-
    rf_res |>
    tune::collect_predictions(parameters = rf_best) |>
    yardstick::roc_auc(retentie, .pred_0)

  # Add model name and AUC to df_model_results
  df_model_results <-
    df_model_results |>
    tibble::add_row(model = "Random Forest", auc = rf_auc_highest$.estimate)

  last_rf_mod <-
    parsnip::rand_forest(mtry = rf_best$mtry,
                min_n = rf_best$min_n,
                trees = 1000) |>
    parsnip::set_engine("ranger", num.threads = cores, importance = "impurity") |>
    parsnip::set_mode("classification")

  last_rf_workflow <-
    rf_workflow |>
    workflows::update_model(last_rf_mod)

  last_fit_rf <-
    last_rf_workflow |>
    tune::last_fit(splits)
  


  # Determine which of the models is best based on highest AUC/ROC
  df_model_results <- df_model_results |>
    dplyr::mutate(number = dplyr::row_number()) |>
    dplyr::mutate(best = ifelse(auc == max(auc), TRUE, FALSE)) |>
    dplyr::arrange(number)

  # Determine the best model
  best_model     <- df_model_results$model[df_model_results$best == TRUE][1]
  best_model_auc <- round(df_model_results$auc[df_model_results$best == TRUE], 4)[1]

  # Build the final models
  last_lr_mod <-
    parsnip::logistic_reg(penalty = lr_best$penalty, mixture = 1) |>
    parsnip::set_engine("glmnet") |>
    parsnip::set_mode("classification")

  # Update the workflows
  last_lr_workflow <-
    lr_workflow |>
    workflows::update_model(last_lr_mod)

  # Make a final fit for both models so we can save it for later use
  last_fit_lr <-
    last_lr_workflow |>
    tune::last_fit(splits)

  last_fit_rf <-
    last_rf_workflow |>
    tune::last_fit(splits)

  last_fits <- list(last_fit_lr, last_fit_rf) |>
    stats::setNames(c("Logistic Regression", "Random Forest"))

  # Determine which model is best
  if (best_model == "Logistic Regression") {
    last_fit <- last_fit_lr
  } else if (best_model == "Random Forest") {
    last_fit <- last_fit_rf
  }

  list(last_fit = last_fit, best_model = best_model)

}
