## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## check_quarto.R ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Helper functions for checking and installing Quarto CLI
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' Controleer of Quarto CLI is geïnstalleerd
#'
#' Verifieert of de Quarto command-line interface (CLI) is geïnstalleerd en
#' beschikbaar is op het systeem. Het `quarto` R package (in nfwa Imports)
#' is slechts een wrapper rond de Quarto CLI, dus de CLI moet apart
#' worden geïnstalleerd.
#'
#' @return Logisch. `TRUE` als Quarto CLI is geïnstalleerd, `FALSE` anders.
#'
#' @details
#' Deze functie controleert:
#' \itemize{
#'   \item Of het `quarto` R package is geïnstalleerd
#'   \item Of Quarto CLI beschikbaar is (via `quarto::quarto_path()`)
#' }
#'
#' @examples
#' \dontrun{
#' if (check_quarto_installed()) {
#'   message("Quarto is klaar voor gebruik")
#' } else {
#'   install_quarto()
#' }
#' }
#'
#' @keywords internal
#' @export
check_quarto_installed <- function() {
  # Check if quarto R package is available
  if (!requireNamespace("quarto", quietly = TRUE)) {
    return(FALSE)
  }

  # Check if Quarto CLI is available
  quarto_path <- tryCatch(
    quarto::quarto_path(),
    error = function(e) NULL
  )

  !is.null(quarto_path)
}

#' Installeer of probleemoplossing voor Quarto
#'
#' Verschaft instructies voor het installeren van de Quarto command-line
#' interface (CLI). Het `quarto` R package (al in nfwa Imports) vereist dat
#' Quarto CLI apart op uw systeem wordt geïnstalleerd.
#'
#' @return Tekenreeks met installatie-instructies (onzichtbaar).
#'
#' @details
#' # Installatiestappen
#'
#' De Quarto CLI moet worden geïnstalleerd voordat u PDF-rapporten kunt
#' genereren met `render_report()`. Het is gescheiden van het R package.
#'
#' ## Windows
#' 1. Download het installatieprogramma van https://quarto.org/docs/getting-started/installation.html
#' 2. Voer het `.msi` installatieprogramma uit
#' 3. Start R opnieuw op en probeer het opnieuw
#'
#' ## macOS
#' ```bash
#' brew install quarto
#' ```
#' Of download van https://quarto.org/docs/getting-started/installation.html
#'
#' ## Linux
#' ```bash
#' # Debian/Ubuntu
#' sudo apt-get install quarto
#'
#' # Of download van:
#' # https://quarto.org/docs/getting-started/installation.html
#' ```
#'
#' ## Na installatie
#' 1. Start R opnieuw op (vernieuw uw R-sessie of RStudio)
#' 2. Controleer installatie met `check_quarto_installed()`
#' 3. Gebruik `render_report()` om PDF-rapporten te genereren
#'
#' @examples
#' \dontrun{
#' # Toon installatie-instructies
#' install_quarto()
#'
#' # Later, controleer of het werkt
#' check_quarto_installed()
#' }
#'
#' @export
install_quarto <- function() {
  msg <- paste0(
    "\n",
    cli::rule("Quarto CLI installatie vereist", width = 70),
    "\n\n",
    "Het nfwa package vereist de Quarto command-line interface (CLI) voor\n",
    "het genereren van PDF-rapporten. Het Quarto R package (dat we al hebben)\n",
    "is slechts een wrapper - u moet Quarto CLI apart installeren.\n\n",
    "Installatie URL:\n",
    "  {.url https://quarto.org/docs/getting-started/installation.html}\n\n"
  )

  # Platform-specific instructions
  if (.Platform$OS.type == "windows") {
    msg <- paste0(
      msg,
      "Voor Windows:\n",
      "  1. Download het .msi installatieprogramma van bovenstaande link\n",
      "  2. Voer het installatieprogramma uit\n",
      "  3. Start R/RStudio opnieuw op\n",
      "  4. Voer uit: nfwa::check_quarto_installed()\n\n"
    )
  } else if (Sys.info()["sysname"] == "Darwin") {
    msg <- paste0(
      msg,
      "Voor macOS:\n",
      "  1. Installeer via Homebrew: brew install quarto\n",
      "  2. Of download van de bovenstaande link\n",
      "  3. Start R/RStudio opnieuw op\n",
      "  4. Voer uit: nfwa::check_quarto_installed()\n\n"
    )
  } else if (.Platform$OS.type == "unix") {
    msg <- paste0(
      msg,
      "Voor Linux (Debian/Ubuntu):\n",
      "  1. Voer uit: sudo apt-get install quarto\n",
      "  2. Of download van de bovenstaande link\n",
      "  3. Start R/RStudio opnieuw op\n",
      "  4. Voer uit: nfwa::check_quarto_installed()\n\n"
    )
  }

  msg <- paste0(
    msg,
    cli::rule(width = 70),
    "\n"
  )

  cat(msg)
  invisible(msg)
}
