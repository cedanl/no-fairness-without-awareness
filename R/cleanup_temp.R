#' Verwijder tijdelijke bestanden van NFWA analyse
#'
#' Deze functie verwijdert de tijdelijke map (`temp/`) die wordt aangemaakt
#' door [run_nfwa()]. Gebruik deze functie na het genereren van je PDF rapport
#' om de tijdelijke bestanden op te ruimen.
#'
#' @param temp_dir Pad naar de tijdelijke map. Standaard: "temp" in de
#'   huidige working directory.
#' @param confirm Logisch. Als `TRUE` (standaard), vraagt de functie om
#'   bevestiging voordat bestanden worden verwijderd. Zet op `FALSE` om
#'   automatisch te verwijderen zonder bevestiging.
#'
#' @return Onzichtbaar `TRUE` als succesvol verwijderd, `FALSE` als de map
#'   niet bestaat of niet verwijderd kon worden.
#'
#' @details
#' De `temp/` map bevat:
#' \itemize{
#'   \item Dichtheidsplots (`fairness_density_*.png`)
#'   \item Fairness-check plots (`fairness_plot_*.png`)
#'   \item Conclusies lijst (`conclusions_list.rds`)
#'   \item Resultatentabel (`result_table.png`)
#' }
#'
#' **Let op:** Zorg ervoor dat je [render_report()] hebt uitgevoerd voordat
#' je deze functie aanroept, anders kun je geen PDF rapport meer genereren.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Na het uitvoeren van run_nfwa() en render_report():
#' cleanup_temp()
#'
#' # Zonder bevestiging:
#' cleanup_temp(confirm = FALSE)
#' }
cleanup_temp <- function(temp_dir = "temp", confirm = TRUE) {

  # Check if temp directory exists
  if (!dir.exists(temp_dir)) {
    message("Tijdelijke map '", temp_dir, "' bestaat niet.")
    return(invisible(FALSE))
  }

  # Get list of files in temp directory
  temp_files <- list.files(temp_dir, full.names = TRUE)

  if (length(temp_files) == 0) {
    message("Tijdelijke map '", temp_dir, "' is al leeg.")
    # Remove empty directory
    unlink(temp_dir, recursive = TRUE)
    message("Lege map verwijderd.")
    return(invisible(TRUE))
  }

  # Ask for confirmation if needed
  if (confirm) {
    message("\nDe volgende tijdelijke bestanden worden verwijderd:")
    message(paste("  -", basename(temp_files), collapse = "\n"))
    message("\nWeet je zeker dat je deze bestanden wilt verwijderen? (Y/n)")

    response <- tolower(trimws(readline(prompt = "> ")))

    if (!response %in% c("Y", "yes", "yes", "y")) {
      message("Opschonen geannuleerd.")
      return(invisible(FALSE))
    }
  }

  # Remove the temp directory and all its contents
  tryCatch({
    unlink(temp_dir, recursive = TRUE)
    message("Tijdelijke map '", temp_dir, "' succesvol verwijderd.")
    return(invisible(TRUE))
  }, error = function(e) {
    warning("Fout bij verwijderen van tijdelijke map: ", e$message)
    return(invisible(FALSE))
  })
}
