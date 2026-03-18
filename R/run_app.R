#' Start de NFWA Shiny applicatie
#'
#' Opent een interactieve webapplicatie waarmee de NFWA kansengelijkheidsanalyse
#' uitgevoerd kan worden zonder R-kennis. Gebruikers kunnen CSV bestanden uploaden,
#' opleidingsgegevens invullen en een PDF rapport downloaden.
#'
#' @param ... Extra argumenten die doorgegeven worden aan \code{shiny::runApp()},
#'   zoals \code{port} of \code{launch.browser}.
#'
#' @return Wordt normaal niet teruggegeven; de applicatie draait totdat de
#'   gebruiker deze sluit.
#'
#' @details
#' De applicatie vereist de volgende packages:
#' \itemize{
#'   \item \code{shiny}: voor de webinterface
#'   \item \code{bslib}: voor de styling
#' }
#'
#' Installeer ze indien nodig met:
#' \code{install.packages(c("shiny", "bslib"))}
#'
#' @seealso \code{\link{analyze_fairness}} voor directe gebruik vanuit R.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' nfwa::run_app()
#' }
run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop(
      "Package 'shiny' is vereist om de app te starten.\n",
      "Installeer het met: install.packages('shiny')"
    )
  }
  if (!requireNamespace("bslib", quietly = TRUE)) {
    stop(
      "Package 'bslib' is vereist om de app te starten.\n",
      "Installeer het met: install.packages('bslib')"
    )
  }

  app_dir <- system.file("shiny-app", package = "nfwa")

  if (app_dir == "") {
    stop("Shiny app bestanden niet gevonden. Herinstalleer het nfwa package.")
  }

  shiny::runApp(app_dir, ...)
}
