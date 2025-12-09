concatenate_list <- function(l, 
                             lang = "nl", 
                             extend = TRUE, 
                             tolower = FALSE, 
                             backtick = FALSE) {
  
  if (tolower) {
    l <- tolower(l)
  }
  if (backtick) {
    l <- backtick(l)
  }
  if (lang == "en") {
    last <- ", and "
  } else if (lang == "nl") {
    last <- " en "
  } else {
    last <- ", "
  }
  
  if (extend) {
    collapse <- glue::glue_collapse(l, sep = ", ", last = last)
  } else {
    collapse <- glue::glue_collapse(l, sep = ", ")
  }
  
  collapse
  
}


# Function to determine fairness inferences
get_fairness_conclusions <- function(df, variabele, succes = "retentie") {
  
  text <- ""
  
  # Define the groups
  df_variables <- df |>
    filter(Variabele == stringr::str_to_title(variabele),
           N > 14) 
  
  if (any(df_variables$Bias == "Ja")) {
    conclusion <- ""
  } else {
    conclusion <- glue("Er is geen sprake van bias in {succes} op basis van {tolower(variabele)}.")
  }
  
  # Determine the groups with negative bias
  if (any(df_variables$`Negatieve Bias` > 1)) {
    negative_bias_list <- df_variables |>
      filter(`Negatieve Bias` > 1) |> 
      pull(Text) |>
      paste(collapse = ", ")
    
    # Replace the final comma by 'en'
    negative_bias_list <- concatenate_list(negative_bias_list)
    negative_bias <- glue("Er is een negatieve bias voor {negative_bias_list}.")
  } else {
    negative_bias <- ""
  }
  
  # Determine the groups with positive bias
  if (any(df_variables$`Positieve Bias` > 1)) {
    positive_bias_list <- df_variables |>
      filter(`Positieve Bias` > 1) |> 
      pull(Text) |>
      paste(collapse = ", ")
    
    # Replace the final comma by 'en'
    positive_bias_list <- concatenate_list(positive_bias_list)
    positive_bias <- glue("Er is een positieve bias voor {positive_bias_list}.")
  } else {
    positive_bias <- ""
  }
  
  text <- glue("{conclusion} {negative_bias} {positive_bias}")
  
  text
  
}
