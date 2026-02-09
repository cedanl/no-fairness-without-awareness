# Function to determine the order of a number of levels
get_levels <- function(df, formal = FALSE) {
  ## Set levels
  levels <- list()
  if (formal) {
    for (i in df$VAR_Formal_variable) {
      levels[[i]] <- df$VAR_Level_NL[df$VAR_Formal_variable == i]
    }
  } else {
    for (i in df$VAR_Simple_variable) {
      levels[[i]] <- df$VAR_Level_NL[df$VAR_Simple_variable == i]
    }
  }
  levels
}

# Function to convert fairness analysis df to a wide df
get_df_fairness_wide <- function(df_list,
                                 df_data,
                                 df_levels,
                                 sensitive_variables) {
  levels <- get_levels(df_levels)
  ## Create a dataframe with the variables based on sensitive_variables
  df_vars <- do.call(rbind, lapply(names(levels), function(group) {
    data.frame(
      FRN_Group = group,
      FRN_Subgroup = levels[[group]],
      stringsAsFactors = FALSE
    )
  })) |>
    ## dplyr::filter on sensitive_labels
    dplyr::filter(FRN_Group %in% sensitive_variables) |>
    ## Order by the order in sensitive_labels
    dplyr::mutate(FRN_Group = factor(FRN_Group, levels = sensitive_variables)) |>
    dplyr::arrange(FRN_Group)
  
  df_bias <- tibble::tibble(FRN_Bias = c("Geen Bias", "Negatieve Bias", "Positieve Bias"))
  
  # Combine df_vars and df_bias
  df_vars_bias <- df_vars |>
    tidyr::crossing(df_bias)
  
  df <- dplyr::bind_rows(df_list) |>
    dplyr::group_by(FRN_Group, FRN_Subgroup, FRN_Bias) |>
     dplyr::summarise(FRN_Bias_count = dplyr::n(), .groups = "drop") |>
    dplyr::full_join(
      df_vars_bias,
      by = c(
        "FRN_Group" = "FRN_Group",
        "FRN_Subgroup" = "FRN_Subgroup",
        "FRN_Bias" = "FRN_Bias"
      )
    ) |>
    tidyr::pivot_wider(
      names_from = FRN_Bias,
      values_from = FRN_Bias_count,
      values_fill = list(FRN_Bias_count = 0)
    ) |>
    tidyr::replace_na(list(
      `Geen Bias` = 0,
      `Negatieve Bias` = 0,
      `Positieve Bias` = 0
    )) |>
    dplyr::rename(Variabele = FRN_Group, Groep = FRN_Subgroup)
  
  add_missing_cols <- function(data, cols, fill = 0) {
    missing <- setdiff(cols, names(data))
    if (length(missing) == 0)
      return(data)
    # create new columns programmatically and fill with `fill`
    data |>
      dplyr::mutate(!!!setNames(rep(list(fill), length(missing)), missing))
  }
  
  df <- add_missing_cols(df, c("Geen Bias", "Negatieve Bias", "Positieve Bias")) |>
    dplyr::select(c(
      "Variabele",
      "Groep",
      "Geen Bias",
      "Negatieve Bias",
      "Positieve Bias"
    ))
  
  df_counts <- df_data |>
    dplyr::select(tidyselect::all_of(sensitive_variables)) |>
    tidyr::pivot_longer(cols = tidyselect::all_of(sensitive_variables)) |>
    dplyr::count(name, value, name = "N") |>
    dplyr::group_by(name) |>
    dplyr::mutate(Perc = round(N / sum(N) * 100, 1)) |>
    dplyr::ungroup()
  
  # Make the df wide
  df_wide <- df |>
    
    # Adjust the Bias
    dplyr::mutate(
      Bias = dplyr::case_when(
        `Negatieve Bias` > 1 | `Positieve Bias` > 1 ~ "Ja",
        `Geen Bias` == 0 &
          `Negatieve Bias` == 0 & `Positieve Bias` == 0 ~ "NTB",
        .default = "Nee"
      )
    ) |>
    
    # Sort the Variable and Group
    # Make levels unique based on the first occurence (to avoid conflicts for repeating levels)
    dplyr::mutate(
      Variabele = factor(Variabele, levels = sensitive_variables),
      Groep = factor(Groep, levels = unique(df_vars$FRN_Subgroup, fromLast = FALSE))
    ) |>
    dplyr::select(Variabele,
           Groep,
           Bias,
           `Geen Bias`,
           `Negatieve Bias`,
           `Positieve Bias`) |>
    dplyr::arrange(Variabele, Groep)
  
  # Add numbers and percentages
  df_wide_2 <- df_wide |>
    dplyr::left_join(df_counts, by = c("Variabele" = "name", "Groep" = "value")) |>
    dplyr::select(Variabele, Groep, N, tidyselect::everything()) |>
    dplyr::mutate(N = tidyr::replace_na(N, 0), Perc = tidyr::replace_na(Perc, 0)) |>
    dplyr::mutate(Perc = format(Perc, decimal.mark = ",", nsmall = 1)) |>
    dplyr::filter(N > 0) |>
    dplyr::select(Variabele,
           Groep,
           N,
           Perc,
           Bias,
           `Geen Bias`,
           `Negatieve Bias`,
           `Positieve Bias`)
  
  # Add labels and text to the groups based on df_levels
  df_wide_3 <- df_wide_2 |>
    dplyr::left_join(
      df_levels |>
        dplyr::filter(!is.na(VAR_Level_label_NL_description)) |>
        dplyr::select(VAR_Level_NL, VAR_Level_label_NL_description, VAR_Formal_variable) |>
        dplyr::distinct(),
      by = c("Groep" = "VAR_Level_NL", "Variabele" = "VAR_Formal_variable")
    ) |>
    dplyr::mutate(
      Groep_label = dplyr::if_else(
        !is.na(VAR_Level_label_NL_description),
        VAR_Level_label_NL_description,
        Groep
      ),
      Text = glue::glue("{Groep_label} ({Groep}: N = {N}, {Perc}%)")
    ) |>
    dplyr::select(-VAR_Level_label_NL_description) |>
    dplyr::mutate(Variabele = stringr::str_to_title(Variabele)) |>
    dplyr::select(Variabele, Groep, Groep_label, tidyselect::everything(), Text)
  
  df_wide_3
}
