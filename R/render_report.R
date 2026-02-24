#' Render PDF rapport van NFWA analyse
#'
#' Deze functie genereert een PDF rapport met de resultaten van de NFWA
#' fairness-analyse. Het rapport bevat de conclusies en visualisaties die
#' gegenereerd zijn door \code{\link{run_nfwa}}.
#'
#' Het PDF bestand wordt opgeslagen in de huidige working directory van de
#' gebruiker (zie \code{\link{getwd}}).
#'
#' @param opleidingsnaam Naam van de opleiding (bijv. "Informatica")
#' @param opleidingsvorm Vorm van de opleiding: "VT" (voltijd), "DT" (deeltijd),
#'   of "DU" (duaal)
#' @param cleanup_temp Logisch. Als `TRUE`, wordt de tijdelijke map automatisch
#'   verwijderd na het genereren van het PDF rapport. Standaard: `FALSE`.
#'
#' @return Pad naar het gegenereerde PDF bestand in de working directory
#'   (invisible)
#'
#' @details
#' Deze functie vereist:
#' \itemize{
#'   \item Quarto geinstalleerd op het systeem (https://quarto.org)
#'   \item Het \code{quarto} R package
#'   \item Output van \code{\link{run_nfwa}} in de temp/ directory
#' }
#'
#' Als Quarto niet geinstalleerd is, krijgt de gebruiker een waarschuwing
#' en wordt er geen PDF gegenereerd.
#'
#' Na het genereren van het PDF rapport, kun je de tijdelijke bestanden
#' verwijderen met \code{\link{cleanup_temp}} of door `cleanup_temp = TRUE`
#' te gebruiken in deze functie.
#'
#' @seealso \code{\link{cleanup_temp}} om tijdelijke bestanden handmatig te
#'   verwijderen.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Na het uitvoeren van run_nfwa():
#' render_report(
#'   opleidingsnaam = "Informatica",
#'   opleidingsvorm = "VT"
#' )
#'
#' # Met automatische cleanup:
#' render_report(
#'   opleidingsnaam = "Informatica",
#'   opleidingsvorm = "VT",
#'   cleanup_temp = TRUE
#' )
#' }
render_report <- function(opleidingsnaam, opleidingsvorm, cleanup_temp = FALSE) {

  # Installeer benodigde dependencies (alleen eerste keer)
  if (!tinytex::is_tinytex()) {
    message("TinyTeX niet gevonden - installeren... Dit gebeurt eenmalig")
    tinytex::install_tinytex()
  }
  
  # Controleer Quarto installatie
  if (!check_quarto_installed()) {
    stop(
      "Quarto CLI is niet geinstalleerd of niet gevonden in het systeem.\n",
      "\n",
      "Gebruik: install_quarto() voor gedetailleerde installatie-instructies"
    )
  }

  # Determine template path (use package template)
  qmd_template <- system.file("templates", "render_pdf.qmd", package = "nfwa")
  
  # Fallback to inst/templates for development
  if (!file.exists(qmd_template) || qmd_template == "") {
    qmd_template <- "inst/templates/render_pdf.qmd"
  }

  # Check if template exists
  if (!file.exists(qmd_template)) {
    stop("Quarto template niet gevonden: ", qmd_template)
  }

  # Check if required temp files exist (use relative path for Quarto/LaTeX)
  temp_dir <- "temp"
  required_files <- c(
    "conclusions_list.rds",
    "result_table.png"
  )

  missing_files <- required_files[!file.exists(file.path(temp_dir, required_files))]
  if (length(missing_files) > 0) {
    stop("Benodigde temp bestanden niet gevonden: ",
         paste(missing_files, collapse = ", "),
         "\nVoer eerst run_nfwa() uit.")
  }

  # Generate output filename
  output_filename <- paste0(
    "kansengelijkheidanalysis_",
    gsub(" ", "_", tolower(opleidingsnaam)),
    "_",
    opleidingsvorm,
    ".pdf"
  )

  message("\nPDF rapport genereren...")

  # Store current working directory
  work_dir <- getwd()

  # Copy template to working directory so LaTeX can find relative paths
  local_template <- file.path(work_dir, "render_pdf_temp.qmd")
  file.copy(qmd_template, local_template, overwrite = TRUE)

  # Ensure cleanup of temporary template
  on.exit(unlink(local_template), add = TRUE)

  # Render the report from the local copy
  # This ensures LaTeX can find files via relative paths
  tryCatch({
    quarto::quarto_render(
      input = local_template,
      output_file = output_filename,
      quiet = TRUE,
      execute_params = list(
        subtitle = paste0(opleidingsnaam, " ", opleidingsvorm),
        temp_dir = temp_dir,  # Use relative path "temp"
        work_dir = normalizePath(work_dir, winslash = "/")
      )
    )

    # PDF should be in working directory
    pdf_path <- file.path(work_dir, output_filename)

    if (file.exists(pdf_path)) {
      message("\nPDF rapport gegenereerd!")
      message("Locatie: ", pdf_path)

      # Cleanup temp directory if requested
      if (cleanup_temp) {
        message("\nTijdelijke bestanden opruimen...")
        cleanup_success <- nfwa::cleanup_temp(temp_dir = temp_dir, confirm = FALSE)
        if (cleanup_success) {
          message("Tijdelijke bestanden verwijderd.")
        }
      } else {
        message("\nTip: Gebruik cleanup_temp() om tijdelijke bestanden te verwijderen.")
      }

      return(invisible(pdf_path))
    } else {
      warning("PDF bestand niet gevonden op verwachte locatie:\n  ", pdf_path,
              "\n\nMogelijk probleem met Quarto configuratie.")
      return(invisible(NULL))
    }

  }, error = function(e) {
    stop("Fout bij genereren van PDF rapport:\n  ", e$message)
  })
}
