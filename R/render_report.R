#' Render PDF rapport van NFWA analyse
#'
#' Deze functie genereert een PDF rapport met de resultaten van de NFWA
#' fairness-analyse. Het rapport bevat de conclusies en visualisaties die
#' gegenereerd zijn door \code{\link{run_nfwa}}.
#'
#' @param opleidingsnaam Naam van de opleiding (bijv. "Informatica")
#' @param opleidingsvorm Vorm van de opleiding: "VT" (voltijd), "DT" (deeltijd),
#'   of "DU" (duaal)
#' @param output_dir Directory waar het PDF rapport opgeslagen moet worden.
#'   Standaard: "output"
#' @param qmd_template Pad naar het Quarto template bestand. Standaard gebruikt
#'   het de meegeleverde template in het package.
#'
#' @return Pad naar het gegenereerde PDF bestand (invisible)
#'
#' @details
#' Deze functie vereist:
#' \itemize{
#'   \item Quarto geïnstalleerd op het systeem (https://quarto.org)
#'   \item Het \code{quarto} R package
#'   \item Output van \code{\link{run_nfwa}} in de output/cache/ directory
#' }
#'
#' Als Quarto niet geïnstalleerd is, krijgt de gebruiker een waarschuwing
#' en wordt er geen PDF gegenereerd.
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
#' }
render_report <- function(opleidingsnaam,
                          opleidingsvorm,
                          output_dir = "output",
                          qmd_template = NULL) {

  # Check if Quarto is available
  quarto_available <- requireNamespace("quarto", quietly = TRUE) &&
    !is.null(tryCatch(quarto::quarto_path(), error = function(e) NULL))

  if (!quarto_available) {
    message("\nLet op: Quarto niet geïnstalleerd - PDF generatie overgeslagen")
    message("  Installeer Quarto vanaf https://quarto.org voor PDF rapporten")
    return(invisible(NULL))
  }

  # Determine template path
  if (is.null(qmd_template)) {
    # Use package template
    qmd_template <- system.file("templates", "render_pdf.qmd", package = "nfwa")

    # Fallback to scripts/render_pdf.qmd for development
    if (!file.exists(qmd_template) || qmd_template == "") {
      qmd_template <- "scripts/render_pdf.qmd"
    }
  }

  # Check if template exists
  if (!file.exists(qmd_template)) {
    stop("Quarto template niet gevonden: ", qmd_template,
         "\nGebruik qmd_template parameter om een eigen template op te geven.")
  }

  # Check if required cache files exist
  cache_dir <- file.path("output", "cache")
  required_files <- c(
    "conclusions_list.rds",
    "result_table.png"
  )

  missing_files <- required_files[!file.exists(file.path(cache_dir, required_files))]
  if (length(missing_files) > 0) {
    stop("Benodigde cache bestanden niet gevonden: ",
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
  message("  Template: ", qmd_template)
  message("  Output: ", output_filename)

  # Get template directory for relative paths in qmd
  template_dir <- dirname(qmd_template)

  # Render the report
  tryCatch({
    quarto::quarto_render(
      input = qmd_template,
      output_file = output_filename,
      execute_params = list(
        subtitle = paste0(opleidingsnaam, " ", opleidingsvorm)
      )
    )

    # Create output directory if it doesn't exist
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    # Determine where the PDF was created
    pdf_source <- file.path(template_dir, output_filename)

    # Move to output directory
    pdf_dest <- file.path(output_dir, output_filename)

    if (file.exists(pdf_source)) {
      file.rename(pdf_source, pdf_dest)
      message("  \u2713 PDF rapport: ", pdf_dest)
      return(invisible(pdf_dest))
    } else {
      warning("PDF bestand niet gevonden op verwachte locatie: ", pdf_source)
      return(invisible(NULL))
    }

  }, error = function(e) {
    stop("Fout bij genereren van PDF rapport:\n  ", e$message)
  })
}
