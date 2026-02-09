#' Bepaal de grootste (geprivilegieerde) groep
#'
#' Identificeert de meest voorkomende subgroep binnen een variabele.
#' Deze groep wordt gebruikt als referentie (geprivilegieerde groep) in
#' fairness-analyses. Bij gelijke aantallen wordt de eerste gekozen.
#'
#' @param df Data frame met de data.
#' @param var Character. Naam van de variabele waarvan de grootste groep
#'   bepaald moet worden.
#'
#' @return Character. Naam van de meest voorkomende subgroep.
#'
#' @export
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
