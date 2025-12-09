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
    
    ## Filter on sensitive_labels
    filter(FRN_Group %in% sensitive_variables) |>
    
    ## Order by the order in sensitive_labels
    mutate(FRN_Group = factor(FRN_Group, levels = sensitive_variables)) |>
    arrange(FRN_Group)
  
  df_bias <- tibble(FRN_Bias = c("Geen Bias", "Negatieve Bias", "Positieve Bias"))
  
  # Combine df_vars and df_bias
  df_vars_bias <- df_vars |>
    crossing(df_bias)
  
  # Total size of the data set
  total_rows <- nrow(bind_rows(df_list))
  
  df <- bind_rows(df_list) |>
    group_by(FRN_Group, FRN_Subgroup, FRN_Bias) |>
    summarise(FRN_Bias_count = n(), .groups = "drop") |>
    full_join(
      df_vars_bias,
      by = c(
        "FRN_Group" = "FRN_Group",
        "FRN_Subgroup" = "FRN_Subgroup",
        "FRN_Bias" = "FRN_Bias"
      )
    ) |>
    pivot_wider(
      names_from = FRN_Bias,
      values_from = FRN_Bias_count,
      values_fill = list(FRN_Bias_count = 0)
    ) |>
    replace_na(list(
      `Geen Bias` = 0,
      `Negatieve Bias` = 0,
      `Positieve Bias` = 0
    )) |>
    rename(Variabele = FRN_Group, Groep = FRN_Subgroup)
  
  add_missing_cols <- function(data, cols, fill = 0) {
    missing <- setdiff(cols, names(data))
    if (length(missing) == 0)
      return(data)
    # create new columns programmatically and fill with `fill`
    data %>%
      mutate(!!!setNames(rep(list(fill), length(missing)), missing))
  }
  
  df <- add_missing_cols(df, c("Geen Bias", "Negatieve Bias", "Positieve Bias")) |>
    select(c(
      "Variabele",
      "Groep",
      "Geen Bias",
      "Negatieve Bias",
      "Positieve Bias"
    ))
  
  df_counts <- df_data |>
    select(all_of(sensitive_variables)) |>
    pivot_longer(cols = all_of(sensitive_variables)) |>
    count(name, value, name = "N") |>
    group_by(name) |>
    mutate(Perc = round(N / sum(N) * 100, 1)) |>
    ungroup()
  
  # Make the df wide
  df_wide <- df |>
    
    # Adjust the Bias
    mutate(
      Bias = case_when(
        `Negatieve Bias` > 1 | `Positieve Bias` > 1 ~ "Ja",
        `Geen Bias` == 0 &
          `Negatieve Bias` == 0 & `Positieve Bias` == 0 ~ "NTB",
        .default = "Nee"
      )
    ) |>
    
    # Sort the Variable and Group
    # Make levels unique based on the first occurence (to avoid conflicts for repeating levels)
    mutate(
      Variabele = factor(Variabele, levels = sensitive_variables),
      Groep = factor(Groep, levels = unique(df_vars$FRN_Subgroup, fromLast = FALSE))
    ) |>
    select(Variabele,
           Groep,
           Bias,
           `Geen Bias`,
           `Negatieve Bias`,
           `Positieve Bias`) |>
    arrange(Variabele, Groep)
  
  # Add numbers and percentages
  df_wide_2 <- df_wide |>
    left_join(df_counts, by = c("Variabele" = "name", "Groep" = "value")) |>
    select(Variabele, Groep, N, everything()) |>
    mutate(N = replace_na(N, 0), Perc = replace_na(Perc, 0)) |>
    mutate(Perc = format(Perc, decimal.mark = ",", nsmall = 1)) |>
    filter(N > 0) |>
    select(Variabele,
           Groep,
           N,
           Perc,
           Bias,
           `Geen Bias`,
           `Negatieve Bias`,
           `Positieve Bias`)
  
  # Add labels and text to the groups based on df_levels
  df_wide_3 <- df_wide_2 %>%
    left_join(
      df_levels |>
        filter(!is.na(VAR_Level_label_NL_description)) |>
        select(VAR_Level_NL, VAR_Level_label_NL_description, VAR_Formal_variable) |>
        distinct(),
      by = c("Groep" = "VAR_Level_NL", "Variabele" = "VAR_Formal_variable")
    ) |>
    mutate(
      Groep_label = if_else(
        !is.na(VAR_Level_label_NL_description),
        VAR_Level_label_NL_description,
        Groep
      ),
      Text = glue("{Groep_label} ({Groep}: N = {N}, {Perc}%)")
    ) |>
    select(-VAR_Level_label_NL_description) |>
    mutate(Variabele = stringr::str_to_title(Variabele)) |>
    select(Variabele, Groep, Groep_label, everything(), Text)
  
  df_wide_3
}
