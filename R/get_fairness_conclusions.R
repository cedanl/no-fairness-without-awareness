#' Voeg elementen van een lijst samen tot een tekst
#'
#' Concateneert elementen van een character vector tot een leesbare tekst
#' met komma's en een taalspecifieke verbinding voor het laatste element
#' (bijv. "en" in het Nederlands, "and" in het Engels).
#'
#' @param l Character vector met elementen om samen te voegen.
#' @param lang Character. Taalcode voor het verbindingswoord: `"nl"` voor
#'   "en", `"en"` voor "and". Standaard `"nl"`.
#' @param extend Logical. Indien `TRUE` (standaard), wordt het laatste
#'   element verbonden met het taalspecifieke woord; anders alleen komma's.
#' @param tolower Logical. Indien `TRUE`, worden alle elementen naar kleine
#'   letters omgezet. Standaard `FALSE`.
#' @param backtick Logical. Indien `TRUE`, worden elementen omgeven met
#'   backticks. Standaard `FALSE`.
#'
#' @return Een `glue`-object met de samengevoegde tekst.
#'
#' @importFrom glue glue_collapse
#' @export
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


#' Genereer tekstuele conclusies uit fairness-analyse
#'
#' Analyseert een breed fairness data frame en genereert Nederlandstalige
#' conclusies over bias per variabele. Groepen met N <= 14 worden
#' uitgesloten. De functie rapporteert over negatieve en positieve bias.
#'
#' @param df Data frame met fairness-resultaten in breed formaat. Moet de
#'   kolommen `Variabele`, `N`, `Bias`, `Negatieve Bias`, `Positieve Bias`
#'   en `Text` bevatten.
#' @param variabele Character. Naam van de sensitieve variabele om te
#'   analyseren (bijv. `"geslacht"`).
#' @param succes Character. Naam van de uitkomstvariabele voor in de
#'   conclusietekst. Standaard `"retentie"`.
#'
#' @return Een `glue`-object met de conclusietekst over bias.
#'
#' @importFrom dplyr filter pull
#' @importFrom glue glue
#' @importFrom stringr str_to_title
#' @export
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
