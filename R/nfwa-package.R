#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' nfwa: No Fairness Without Awareness - Kansengelijkheidsanalyse
#'
#' Analyseer de kansengelijkheid van een opleiding aan de hand van
#' studiedata. Het package traint prognosemodellen (logistische regressie en
#' random forest) en beoordeelt fairness-metriken per gevoelige variabele,
#' zoals geslacht en vooropleiding.
#'
#' @section Belangrijkste functies:
#' \describe{
#'   \item{\code{\link{run_nfwa}}}{Voer de complete fairness-analyse uit}
#'   \item{\code{\link{transform_data}}}{Transformeer ruwe 1CHO data}
#'   \item{\code{\link{read_metadata}}}{Laad package metadata}
#'   \item{\code{\link{run_models}}}{Train classificatiemodellen}
#' }
#'
#' @section Workflow:
#' 1. Laad metadata met \code{read_metadata()}
#' 2. Transformeer data met \code{transform_data()}
#' 3. Voer analyse uit met \code{run_nfwa()}
#'
#' @references
#' Bakker, T. (2024). No Fairness without Awareness. Toegepast onderzoek naar
#' kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning
#' Technology & Analytics. \doi{10.5281/zenodo.14204674}
#'
#' @name nfwa-package
#' @aliases nfwa
NULL
