library(dplyr)

# Function to create a data frame from the fairness check data
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
