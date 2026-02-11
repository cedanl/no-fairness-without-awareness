#' Maak een fairness-object voor een sensitieve variabele
#'
#' Creert een fairness-checkobject via [fairmodels::fairness_check()] op
#' basis van een DALEX-explainer en een opgegeven sensitieve variabele.
#' Het object bevat fairness-metrieken per subgroep ten opzichte van de
#' geprivilegieerde groep.
#'
#' @param df Data frame met de data. Moet de kolom `retentie` en de kolom
#'   opgegeven in `var` bevatten.
#' @param explainer Een [DALEX::explain()]-object van het getrainde model.
#' @param var Character. Naam van de sensitieve variabele (bijv.
#'   `"geslacht"`).
#' @param privileged Character. Naam van de geprivilegieerde
#'   (referentie)groep.
#' @param verbose Logical. Indien `TRUE`, wordt voortgangsinformatie
#'   getoond. Standaard `FALSE`.
#' @param cutoff Numeriek. Cutoff-waarde voor classificatie. Standaard
#'   `0.2`.
#'
#' @return Een fairness-object van klasse `fairness_check`.
#'
#' @importFrom dplyr select pull all_of
#' @importFrom fairmodels fairness_check
#' @export
get_obj_fairness <- function(df, explainer, var, privileged, verbose = FALSE, cutoff = 0.2) {
  # Define the protected variable
  protected <- df |>
    dplyr::select(-retentie) |>
    dplyr::select(dplyr::all_of({{var}})) |>
    dplyr::pull()
  
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
