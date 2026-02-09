library(dplyr)

#' Transformeer fairness-checkdata naar een gestructureerd data frame
#'
#' Verwerkt de ruwe fairness-checkdata uit een fairness-object tot een
#' gestandaardiseerd data frame met herbenoemde kolommen, fairness-metrieken
#' en groepsgroottes.
#'
#' @param df Data frame met de oorspronkelijke dataset. Moet de kolom
#'   bevatten die overeenkomt met `var`.
#' @param fairness_object Data frame met fairness-checkdata, typisch
#'   afkomstig uit `fairness_object[["fairness_check_data"]]`. Moet de
#'   kolommen `score`, `metric`, `subgroup` en `model` bevatten.
#' @param var Character. Naam van de sensitieve variabele (bijv.
#'   `"geslacht"`).
#'
#' @return Een data frame met kolommen `FRN_Model`, `FRN_Group`,
#'   `FRN_Subgroup`, `FRN_Metric`, `FRN_Score`, `FRN_Fair` en `N`.
#'
#' @importFrom dplyr mutate rename select left_join case_when
#' @importFrom tidyr pivot_longer replace_na
#' @export
get_df_fairness_check_data <- function(df, fairness_object, var) {
  fairness_object <- fairness_object |>
    dplyr::mutate(
      Fair_TF = ifelse(score < 0.8 | score > 1.25, FALSE, TRUE),
      FRN_Metric = case_when(
        grepl("Accuracy equality", metric)       ~ "Accuracy Equality",
        grepl("Predictive parity ratio", metric) ~ "Predictive Parity",
        grepl("Predictive equality", metric)     ~ "Predictive Equality",
        grepl("Equal opportunity", metric)       ~ "Equal Opportunity",
        grepl("Statistical parity", metric)      ~ "Statistical Parity"
      ),
      FRN_Group = var
    ) |>
    rename(
      FRN_Score = score,
      FRN_Subgroup = subgroup,
      FRN_Fair = Fair_TF,
      FRN_Model = model
    ) |>
    select(FRN_Model,
           FRN_Group,
           FRN_Subgroup,
           FRN_Metric,
           FRN_Score,
           FRN_Fair)
  
  # Create a dataframe of the fairness check data
  df_counts <- df |>
    select(!!var) |>
    pivot_longer(cols = c(!!var)) |>
    count(name, value, name = "N")
  
  # Combine with numbers
  fairness_object <- fairness_object |>
    left_join(df_counts, by = c("FRN_Group" = "name", "FRN_Subgroup" = "value")) |>
    replace_na(list(N = 0))
  
  fairness_object
}
