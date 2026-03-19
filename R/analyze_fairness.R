#' Voer complete NFWA fairness-analyse uit op 1CHO data
#'
#' Deze functie voert de volledige No Fairness Without Awareness (NFWA)
#' analyse uit op 1CHO studiedata. Het combineert data transformatie,
#' model training, fairness-analyse en optionele PDF rapportage in een functie.
#'
#' @param data_ev Data frame met 1CHO inschrijvingsdata (EV-bestand, enriched formaat).
#'   Bevat studentgegevens zoals geslacht, vooropleiding, en retentie.
#' @param data_vakhavw Data frame met 1CHO vak/cijfer data (VAKHAVW-bestand).
#'   Bevat behaalde cijfers per vak per student.
#' @param opleidingsnaam Character. Naam van de opleiding zoals deze voorkomt in
#'   de kolom `opleidingscode_naam_opleiding` van de enriched EV-data
#'   (bijv. `"B Tandheelkunde"`). Wordt gebruikt voor filtering en in het rapport.
#' @param eoi Numeric. Minimaal instroomcohort. Alleen studenten die in dit jaar
#'   of later zijn gestart worden meegenomen in de analyse (bijv. `2020` selecteert
#'   cohorten vanaf 2020).
#' @param opleidingsvorm Character. Vorm van de opleiding: "VT" (voltijd),
#'   "DT" (deeltijd), of "DU" (duaal).
#' @param generate_pdf Logical. Als `TRUE`, wordt een PDF rapport gegenereerd.
#'   Standaard: `TRUE`.
#' @param cleanup_temp Logical. Als `TRUE`, worden tijdelijke bestanden
#'   automatisch verwijderd na PDF generatie. Standaard: `FALSE`.
#' @param caption Character. Optionele caption voor visualisaties.
#'   Standaard: automatisch gegenereerd met bron en datum.
#'
#' @return Een invisible list met:
#'   \item{df}{Het getransformeerde dataframe gebruikt voor analyse}
#'   \item{metadata}{De metadata gebruikt voor de analyse}
#'   \item{pdf_path}{Pad naar het gegenereerde PDF rapport (indien generate_pdf = TRUE)}
#'
#' @details
#' Deze functie voert de volgende stappen uit:
#' \enumerate{
#'   \item Laadt metadata (variabelen, sensitieve attributen, labels)
#'   \item Transformeert ruwe 1CHO data naar analyse-klaar formaat
#'   \item Traint machine learning modellen (Logistic Regression & Random Forest)
#'   \item Voert fairness-analyse uit op sensitieve variabelen
#'   \item Genereert visualisaties en conclusies
#'   \item Optioneel: genereert PDF rapport met bevindingen
#' }
#'
#' Vereisten:
#' \itemize{
#'   \item Quarto geinstalleerd (voor PDF generatie)
#'   \item Het \code{quarto} R package
#'   \item TinyTeX (voor LaTeX compilatie)
#' }
#'
#' Output bestanden worden opgeslagen in:
#' \itemize{
#'   \item \code{temp/}: Tussentijdse bestanden (plots, RDS bestanden)
#'   \item Working directory: PDF rapport (indien generate_pdf = TRUE)
#' }
#'
#' @seealso
#' \code{\link{transform_data}} voor data transformatie,
#' \code{\link{run_nfwa}} voor de fairness-analyse,
#' \code{\link{render_report}} voor PDF generatie,
#' \code{\link{cleanup_temp}} voor opruimen tijdelijke bestanden.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Laad je 1CHO enriched data (CSV bestanden met puntkomma separator)
#' data_ev <- read.csv("pad/naar/jouw_EV_enriched_bestand.csv", sep = ";")
#' data_vakhavw <- read.csv("pad/naar/jouw_VAKHAVW_bestand.csv", sep = ";")
#'
#' # Voer complete analyse uit met PDF rapport
#' result <- analyze_fairness(
#'   data_ev = data_ev,
#'   data_vakhavw = data_vakhavw,
#'   opleidingsnaam = "B Tandheelkunde",
#'   eoi = 2020,
#'   opleidingsvorm = "VT",
#'   generate_pdf = TRUE,
#'   cleanup_temp = FALSE
#' )
#'
#' # Bekijk het getransformeerde dataframe
#' head(result$df)
#'
#' # Met automatische cleanup
#' result <- analyze_fairness(
#'   data_ev = data_ev,
#'   data_vakhavw = data_vakhavw,
#'   opleidingsnaam = "B Tandheelkunde",
#'   eoi = 2020,
#'   opleidingsvorm = "VT",
#'   generate_pdf = TRUE,
#'   cleanup_temp = TRUE
#' )
#' }
analyze_fairness <- function(data_ev,
                              data_vakhavw,
                              opleidingsnaam,
                              eoi,
                              opleidingsvorm,
                              generate_pdf = TRUE,
                              cleanup_temp = TRUE,
                              caption = NULL) {

  # Controleer Quarto installatie (vereist voor PDF generatie)
  if (generate_pdf && !check_quarto_installed()) {
    stop(
      "Quarto CLI is niet geinstalleerd of niet gevonden in het systeem.\n",
      "\n",
      "Alternatieven:\n",
      "1. Gebruik: install_quarto() voor installatie-instructies\n",
      "2. Zet 'generate_pdf = FALSE' om alleen analyses uit te voeren zonder PDF"
    )
  }

  # Validate inputs
  if (!is.data.frame(data_ev)) {
    stop("data_ev moet een data frame zijn")
  }
  if (!is.data.frame(data_vakhavw)) {
    stop("data_vakhavw moet een data frame zijn")
  }
  if (!opleidingsvorm %in% c("VT", "DT", "DU")) {
    stop("opleidingsvorm moet 'VT', 'DT', of 'DU' zijn")
  }

  # Validate data contents
  validate_data(data_ev, data_vakhavw, opleidingsnaam, opleidingsvorm)

  # Start message
  message("\n========================================")
  message("NFWA Fairness-Analyse")
  message("========================================")
  message("Opleiding: ", opleidingsnaam, " (", opleidingsvorm, ")")
  message("EOI: ", eoi)
  message("========================================\n")

  # Step 1: Load metadata
  message("Stap 1/4: Metadata inlezen...")
  metadata <- read_metadata()

  sensitive_variables <- metadata$sensitive_variables
  mapping_newname <- metadata$mapping_newname
  df_levels <- metadata$df_levels

  message("  - ", length(metadata$variables), " variabelen")
  message("  - ", length(sensitive_variables), " sensitieve variabelen: ",
          paste(sensitive_variables, collapse = ", "))

  # Step 2: Transform data
  message("\nStap 2/4: Data transformeren...")
  df <- transform_data(
    metadata = metadata,
    opleidingsnaam = opleidingsnaam,
    opleidingsvorm = opleidingsvorm,
    eoi = eoi,
    data_ev = data_ev,
    data_vakhavw = data_vakhavw
  )

  if (nrow(df) == 0) {
    stop(
      "Geen studenten gevonden na filtering.\n",
      "Controleer of de combinatie van opleidingsnaam ('", opleidingsnaam,
      "'), opleidingsvorm ('", opleidingsvorm,
      "') en eoi (>= ", eoi, ") daadwerkelijk data oplevert.",
      call. = FALSE
    )
  }

  # Check of er voldoende studenten zijn per sensitieve variabele.
  # De fairness analyse vereist minimaal 15 studenten per subgroep,
  # en minstens 2 subgroepen per variabele.
  min_per_subgroup <- 15
  for (var in sensitive_variables) {
    if (!var %in% names(df)) next
    tbl <- table(df[[var]])
    bruikbaar <- sum(tbl >= min_per_subgroup)
    if (bruikbaar < 2) {
      warning(
        "Sensitieve variabele '", var, "' heeft minder dan 2 subgroepen met ",
        "minimaal ", min_per_subgroup, " studenten. ",
        "De fairness analyse voor deze variabele zal worden overgeslagen.\n",
        "  Subgroepen: ", paste(names(tbl), " (n=", tbl, ")", sep = "", collapse = ", "),
        "\n  Overweeg een eerder instroomcohort (lagere eoi) te kiezen.",
        call. = FALSE
      )
    }
  }

  message("  - ", nrow(df), " studenten in analyse")
  message("  - Retentie: ", round(mean(df$retentie) * 100, 1), "%")

  # Step 3: Run NFWA analysis
  message("\nStap 3/4: Fairness-analyse uitvoeren...")
  message("  - Modellen trainen...")
  message("  - Fairness checks uitvoeren...")
  message("  - Visualisaties genereren...")

  # Determine cutoff
  cutoff <- sum(df$retentie) / nrow(df)

  # Set default caption if not provided
  if (is.null(caption)) {
    caption <- paste0(
      "Bron: 1CHO data | Analyse: ", format(Sys.Date(), "%B %Y")
    )
  }

  # Run the analysis
  run_nfwa(
    df = df,
    df_levels = df_levels,
    sensitive_variables = sensitive_variables,
    cutoff = cutoff,
    caption = caption,
    eoi = eoi
  )

  message("  - Plots opgeslagen in temp/")
  message("  - Resultaten opgeslagen")
  message("  - Conclusies opgeslagen")

  # Step 4: Generate PDF (optional)
  pdf_path <- NULL
  if (generate_pdf) {
    message("\nStap 4/4: PDF rapport genereren...")

    pdf_path <- render_report(
      opleidingsnaam = opleidingsnaam,
      opleidingsvorm = opleidingsvorm,
      cleanup_temp = cleanup_temp
    )
  } else {
    message("\nStap 4/4: PDF generatie overgeslagen")
    if (!cleanup_temp) {
      message("\nTip: Gebruik cleanup_temp() om tijdelijke bestanden te verwijderen.")
    }
  }

  # Completion message
  message("\n========================================")
  message("NFWA Analyse Compleet!")
  message("========================================")
  if (!is.null(pdf_path)) {
    message("PDF rapport: ", pdf_path)
  }
  message("========================================\n")

  # Return results invisibly
  invisible(list(
    df = df,
    metadata = metadata,
    pdf_path = pdf_path
  ))
}
