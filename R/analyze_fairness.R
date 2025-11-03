## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## analyze_fairness.R ####
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

library(fairmodels)
library(glue)
library(flextable)

colors_default <- c(
  
  # Colors of title, subject, subtitle, caption, background
  title_color                = "black",
  subject_color              = "#808080",
  subtitle_color             = "black",
  subtitle_prefix_color      = "#808080",
  subtitle_warning_color     = "#C8133B",
  caption_color              = "darkgray",
  background_color           = "white",
  
  # Color of text
  text_color                 = "black",
  text_inside_color          = "white",
  
  # Intercept (0) and gridlines
  baseline_color             = "black",
  gridline_color             = "#CBCBCB",
  deadline_color             = "black",
  baseline_color_ses         = "darkgray",
  breakdown_intercept_color  = "black",
  breakdown_segment_color    = "darkgray",
  
  # Fill color
  fill_color                 = "lightgray",
  
  # Line color
  average_line_color         = "#CBCBCB",
  
  # Text color
  average_text_color         = "darkgray",
  
  # Color of annotations
  annotation_text_color      = "black",
  arrow_color                = "darkgray",
  
  # Color of jitter
  jitter_color               = "darkgray",
  
  # Error band color
  se_color                   = "#CBCBCB",
  
  # Band color
  band_color                 = "grey95",
  
  # Positive and negative
  positive_color             = "#466F9D",
  negative_color             = "#C8133B",
  
  # Metrics
  metrics_green              = "#287233",
  metrics_red                = "#C8133B",
  metrics_yellow             = "#FFD966",
  metrics_blue               = "#5FA2CE",
  
  # Bias colors
  color_bias_positive        = "#9DBF9E",
  color_bias_negative        = "#A84268",
  color_bias_neutral         = "#FCB97D",
  color_bias_none            = "#E5E5E5"
)

# Function to make the privileged (majority)
get_largest_group <- function(df, var) {
  # Calculate the frequencies of each subgroup
  df_tally <- table(df[[var]])
  
  # Determine the most common subgroup(s).
  max_frequency <- max(df_tally)
  most_common_subgroups <- names(df_tally[df_tally == max_frequency])
  
  # If there are several, choose the first one (or determine another logic)
  privileged <- most_common_subgroups[1]
  
  privileged
}

# Function to create a fairness object
get_obj_fairness <- function(df, explainer, var, privileged, verbose = FALSE) {
  # Define the protected variable
  protected <- df |>
    select(-Retentie) |>
    select(all_of({{var}})) |>
    pull()
  
  # Create a fairness object
  fairness_object <- fairmodels::fairness_check(
    explainer,
    protected = protected,
    privileged = privileged,
    cutoff = 0.2,
    verbose = verbose,
    colorize = TRUE
  )
  
  # Return the fairness object
  fairness_object
}

get_df_fairness_total <- function(fairness_object) {
  # Create a table from the fairness analysis
  df_fairness <- fairness_object[["fairness_check_data"]] |>
    as.data.frame() |>
    filter(!is.na(score))
  
  # Calculate for each metric whether the score is outside the cutoff
  df_fairness_metric <- df_fairness |>
    
    # For each group, calculate whether the score is outside the cutoff
    mutate(category_outside_borders = ifelse(score < 0.8 |
                                               score > 1.2, "Ja", "Nee")) |>
    
    # For each group, calculate whether there is > 1 Ja
    group_by(metric) |>
    summarise(metric_outside_borders = ifelse(sum(category_outside_borders == "Ja") > 1, "Ja", "Nee"))
  
  # Enrich the table with variable Metric_outside_limits
  df_fairness_total <- df_fairness |>
    
    # For each group, calculate whether the score is outside the cutoff
    mutate(category_outside_borders = ifelse(score < 0.8 |
                                               score > 1.2, "Ja", "Nee")) |>
    
    # Link to the metric
    left_join(df_fairness_metric, by = "metric") |>
    select(-model) |>
    
    # Rename the columns
    rename(
      Metric = metric,
      `Metric buiten grenzen` = metric_outside_borders,
      Score = score,
      Categorie = subgroup,
      `Categorie buiten grenzen` = category_outside_borders
    ) |>
    select(Metric,
           `Metric buiten grenzen`,
           Categorie,
           `Categorie buiten grenzen`)
  
  df_fairness_total
  
}

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

# Function to create the flextable for fairness analysis
get_ft_fairness <- function(ft) {
  
  color_bias_positive <- colors_default[["color_bias_positive"]] # "#9DBF9E"
  color_bias_negative <- colors_default[["color_bias_negative"]] # "#A84268"
  color_bias_neutral  <- colors_default[["color_bias_neutral"]]  # "#FCB97D"
  color_bias_none     <- colors_default[["color_bias_none"]]     # "#E5E5E5"
  
  # Merge the 'Variable' column for visual grouping
  # Apply conditional formatting
  ft <- ft |>
    merge_v(j = ~ Variabele) |>
    fix_border_issues() |>
    theme_vanilla() |>
    set_header_labels(
      Variabele = "Variabele",
      Groep = "Groep",
      N = "N",
      Perc = "%",
      Bias = "Bias",
      `Geen Bias` = "Geen Bias",
      `Negatieve Bias` = "Negatieve Bias",
      `Positieve Bias` = "Positieve Bias"
    ) |>
    autofit() |> 
    italic(j = 1, italic = TRUE, part = "body") |> 
    color(i = ~ `Negatieve Bias` > 1,
          j = c("Groep", "Bias", "Negatieve Bias"),
          color = "white") |>
    color(i = ~ `Positieve Bias` > 1,
          j = c("Groep", "Bias", "Positieve Bias"),
          color = "white") |>
    bg(i = ~ `Negatieve Bias` > 1, 
       j = c("Groep", "Bias", "Negatieve Bias"), 
       bg = color_bias_negative) |>
    bg(i = ~ `Positieve Bias` > 1, 
       j = c("Groep", "Bias", "Positieve Bias"), 
       bg = color_bias_positive) |>
    bg(i = ~ `Negatieve Bias` > 1 & `Positieve Bias` > 1, 
       j = c("Groep", "Bias"), 
       bg = color_bias_neutral) |>
    bg(i = ~ N < 15 & (`Negatieve Bias` > 1 | `Positieve Bias` > 1), 
       j = c("Groep", "Bias"), 
       bg = color_bias_neutral) |>
    bg(i = ~ `Geen Bias` == 0 & `Positieve Bias` == 0 & `Negatieve Bias` == 0,
       j = 2:8,
       bg = color_bias_none) |>
    bold(i = ~ `Negatieve Bias` > 1,
         j = c("Groep", "Bias", "Negatieve Bias")) |>
    bold(i = ~ `Positieve Bias` > 1,
         j = c("Groep", "Bias", "Positieve Bias")) |> 
    valign(j = 1, valign = "top", part = "all") |> 
    align_text_col(align = "left") |> 
    align_nottext_col(align = "center") |> 
    
    # Align % and Bias column
    align(j = 4:5, align = "center", part = "header") |> 
    align(j = 4:5, align = "center")
  
  ft
}

# Function to determine the order of a number of levels
get_levels <- function(formal = FALSE) {
  
  df <- get_df_levels()
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

get_df_levels <- function() {
  
  df_levels <- read.csv("metadata/levels.csv", sep = "\t") |>
    group_by(VAR_Formal_variable) |>
    arrange(VAR_Level_order, .by_group = TRUE) |>
    ungroup()
  
  df_levels
}

# Function to convert fairness analysis df to a wide df
get_df_fairness_wide <- function(df_list, df_data) {
  
  sensitive_variables <- read.csv("metadata/variabelen.csv", sep = ";") |>
    filter(Sensitive) |>
    pull(Variable)
  
  levels <- get_levels()
  
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
  
  df_bias <- tibble(
    FRN_Bias = c("Geen Bias", "Negatieve Bias", "Positieve Bias")
  )
  
  # Combine df_vars and df_bias
  df_vars_bias <- df_vars |> 
    crossing(df_bias)
  
  # Total size of the data set
  total_rows <- nrow(bind_rows(df_list))
  
  df <- bind_rows(df_list) |> 
    group_by(FRN_Group, FRN_Subgroup, FRN_Bias) |>
    summarise(
      FRN_Bias_count = n(), 
      .groups = "drop"
    ) |> 
    full_join(df_vars_bias,
              by = c("FRN_Group" = "FRN_Group", 
                     "FRN_Subgroup" = "FRN_Subgroup",
                     "FRN_Bias" = "FRN_Bias")) |>
    pivot_wider(names_from = FRN_Bias, 
                values_from = FRN_Bias_count,
                values_fill = list(FRN_Bias_count = 0)) |> 
    replace_na(list(`Geen Bias` = 0, `Negatieve Bias` = 0, `Positieve Bias` = 0)) |>
    rename(Variabele = FRN_Group,
           Groep = FRN_Subgroup)
  
  add_missing_cols <- function(data, cols, fill = 0) {
    missing <- setdiff(cols, names(data))
    if (length(missing) == 0) return(data)
    # create new columns programmatically and fill with `fill`
    data %>%
      mutate(!!!setNames(rep(list(fill), length(missing)), missing))
  }
  
  df <- add_missing_cols(df, c("Geen Bias", "Negatieve Bias", "Positieve Bias")) |>
    select(c("Variabele", "Groep", "Geen Bias", "Negatieve Bias", "Positieve Bias"))
  
  df_counts <- df_data |>
    select(all_of(sensitive_variables)) |>
    pivot_longer(cols = all_of(sensitive_variables)) |>
    count(name, value, name = "N") |> 
    group_by(name) |>
    mutate(
      Perc = round(N / sum(N) * 100, 1) 
    ) |> 
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
    select(Variabele, Groep, Bias, `Geen Bias`, `Negatieve Bias`, `Positieve Bias`) |> 
    arrange(Variabele, Groep)
  
  # Add numbers and percentages
  df_wide_2 <- df_wide |> 
    left_join(df_counts, by = c("Variabele" = "name", "Groep" = "value")) |>
    select(Variabele, Groep, N, everything()) |> 
    mutate(
      N = replace_na(N, 0), 
      Perc = replace_na(Perc, 0) 
    ) |> 
    mutate(Perc = format(Perc, decimal.mark = ",", nsmall = 1)) |> 
    filter(N > 0) |> 
    select(Variabele, Groep, N, Perc, Bias, `Geen Bias`, `Negatieve Bias`, `Positieve Bias`) 
  
  df_levels <- get_df_levels()
  
  # Add labels and text to the groups based on df_levels
  df_wide_3 <- df_wide_2 %>%
    left_join(df_levels |> 
                filter(!is.na(VAR_Level_label_NL_description)) |> 
                select(VAR_Level_NL, VAR_Level_label_NL_description) |> 
                distinct(), by = c("Groep" = "VAR_Level_NL")) |> 
    mutate(
      Groep_label = if_else(
        !is.na(VAR_Level_label_NL_description),
        VAR_Level_label_NL_description,
        Groep
      ),
      Text = glue("{Groep_label} ({Groep}: N = {N}, {Perc}%)")
    ) |> 
    select(-VAR_Level_label_NL_description) |> 
    select(Variabele, Groep, Groep_label, everything(), Text)
  
  df_wide_3
}


analyze_fairness <- function(df, explain_lf) {
  
  sensitive_variables <- read.csv("metadata/variabelen.csv", sep = ";") |>
    filter(Sensitive) |>
    pull(Variable)
  
  df_fairness_list <- list()
  
  # Make a fairness analysis
  for (i in 1:length(sensitive_variables)) {
    var <- sensitive_variables[i]
    # Determine the most common subgroup = Privileged
    privileged <- get_largest_group(df, var)
    
    # Create a fairness object
    fairness_object <- get_obj_fairness(df, explain_lf, var, privileged)
    
    # Create a table from the fairness analysis
    df_fairness_total <- get_df_fairness_total(fairness_object)
    
    df_fairness_check_data <- get_df_fairness_check_data(df, fairness_object[["fairness_check_data"]], var)
  
    df_fairness_list[[i]]      <- df_fairness_check_data |>
      mutate(
        FRN_Bias = case_when(
          FRN_Score < 0.8 ~ "Negatieve Bias",
          FRN_Score > 1.25 ~ "Positieve Bias",
          .default = "Geen Bias"
        )
      )
  }

  # Create a table from the fairness analysis
  df_fairness_wide  <- get_df_fairness_wide(df_fairness_list, df)
  
  # Create a flextable
  ft_fairness <- get_ft_fairness(flextable(df_fairness_wide |>
                                             select(-c(Groep_label, Text))))
  
  # Print the flextable
  ft_fairness
  
}


