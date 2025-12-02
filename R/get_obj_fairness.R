library(dplyr)

get_obj_fairness <- function(df, explainer, var, privileged, verbose = FALSE, cutoff = 0.2) {
  # Define the protected variable
  protected <- df |>
    select(-retentie) |>
    select(all_of({{var}})) |>
    pull()
  
  # Create a fairness object
  fairness_object <- fairmodels::fairness_check(
    explainer,
    protected = protected,
    privileged = privileged,
    cutoff = cutoff,
    verbose = verbose,
    colorize = TRUE
  )
  
  # Return the fairness object
  fairness_object
}
