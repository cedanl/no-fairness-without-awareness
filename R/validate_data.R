#' Valideer invoerdata voor de NFWA analyse
#'
#' Controleert of de EV- en VAKHAVW-data de juiste kolommen bevatten,
#' of numerieke kolommen daadwerkelijk numeriek zijn, en of de opgegeven
#' opleidingsnaam in de data voorkomt.
#'
#' @param data_ev Data frame met 1CHO inschrijvingsdata (EV-bestand).
#' @param data_vakhavw Data frame met 1CHO vak/cijfer data (VAKHAVW-bestand).
#' @param opleidingsnaam Character. Naam van de opleiding.
#' @param opleidingsvorm Character. Opleidingsvorm ("VT", "DT", "DU").
#'
#' @return Onzichtbaar `TRUE` als alles in orde is.
#'   Stopt met een foutmelding als er problemen zijn.
#'
#' @keywords internal
validate_data <- function(data_ev, data_vakhavw, opleidingsnaam, opleidingsvorm) {
  ev_names <- tolower(names(data_ev))
  vakhavw_names <- tolower(names(data_vakhavw))

  problemen <- character()

  # --- Verplichte kolommen EV ---
  ev_vereist <- c(
    "persoonsgebonden_nummer",
    "inschrijvingsjaar",
    "opleidingscode_naam_opleiding",
    "opleidingsvorm",
    "eerste_jaar_aan_deze_opleiding_instelling",
    "eerste_jaar_aan_deze_instelling",
    "eerste_jaar_in_het_hoger_onderwijs",
    "diplomajaar_hoogste_vooropleiding",
    "postcodecijfers_student_op_1_oktober",
    "geslacht",
    "leeftijd_per_peildatum_1_oktober",
    "soort_inschrijving_continu_hoger_onderwijs",
    "indicatie_eerstejaars_continu_type_ho_binnen_ho",
    "datum_inschrijving"
  )

  # hoogste_vooropleiding_omschrijving kan twee namen hebben
  heeft_vopl <- "hoogste_vooropleiding_omschrijving_vooropleiding" %in% ev_names ||
    "hoogste_vooropleiding_omschrijving" %in% ev_names

  ontbrekend_ev <- setdiff(ev_vereist, ev_names)
  if (length(ontbrekend_ev) > 0) {
    problemen <- c(problemen, paste0(
      "Ontbrekende kolommen in data_ev: ",
      paste(ontbrekend_ev, collapse = ", ")
    ))
  }
  if (!heeft_vopl) {
    problemen <- c(problemen,
      "Ontbrekende kolom in data_ev: hoogste_vooropleiding_omschrijving (of hoogste_vooropleiding_omschrijving_vooropleiding)"
    )
  }

  # --- Verplichte kolommen VAKHAVW ---
  vakhavw_vereist <- c(
    "persoonsgebonden_nummer",
    "afkorting_vak",
    "cijfer_eerste_centraal_examen",
    "gemiddeld_cijfer_cijferlijst",
    "cijfer_schoolexamen"
  )

  ontbrekend_vakhavw <- setdiff(vakhavw_vereist, vakhavw_names)
  if (length(ontbrekend_vakhavw) > 0) {
    problemen <- c(problemen, paste0(
      "Ontbrekende kolommen in data_vakhavw: ",
      paste(ontbrekend_vakhavw, collapse = ", ")
    ))
  }

  # --- Numerieke kolommen check ---
  ev_numeriek <- c(
    "leeftijd_per_peildatum_1_oktober"
  )
  for (kol in ev_numeriek) {
    if (kol %in% ev_names) {
      vals <- data_ev[[kol]]
      if (!is.numeric(vals) && any(!is.na(vals))) {
        als_num <- suppressWarnings(as.numeric(as.character(vals)))
        pct_na <- mean(is.na(als_num) & !is.na(vals))
        if (pct_na > 0.5) {
          problemen <- c(problemen, paste0(
            "Kolom '", kol, "' in data_ev bevat geen numerieke waarden ",
            "(", round(pct_na * 100), "% niet-numeriek)"
          ))
        }
      }
    }
  }

  vakhavw_numeriek <- c(
    "cijfer_eerste_centraal_examen",
    "gemiddeld_cijfer_cijferlijst",
    "cijfer_schoolexamen"
  )
  for (kol in vakhavw_numeriek) {
    if (kol %in% vakhavw_names) {
      vals <- data_vakhavw[[kol]]
      if (!is.numeric(vals) && any(!is.na(vals))) {
        als_num <- suppressWarnings(as.numeric(as.character(vals)))
        pct_na <- mean(is.na(als_num) & !is.na(vals))
        if (pct_na > 0.5) {
          problemen <- c(problemen, paste0(
            "Kolom '", kol, "' in data_vakhavw bevat geen numerieke waarden ",
            "(", round(pct_na * 100), "% niet-numeriek)"
          ))
        }
      }
    }
  }

  # --- Opleidingsnaam check ---
  if ("opleidingscode_naam_opleiding" %in% ev_names) {
    beschikbaar <- unique(data_ev[["opleidingscode_naam_opleiding"]])
    beschikbaar <- beschikbaar[!is.na(beschikbaar) & nchar(as.character(beschikbaar)) > 0]

    if (!opleidingsnaam %in% beschikbaar) {
      problemen <- c(problemen, paste0(
        "Opleidingsnaam '", opleidingsnaam, "' niet gevonden in data_ev.\n",
        "  Beschikbare opleidingen: ",
        paste(sort(as.character(beschikbaar)), collapse = ", ")
      ))
    }
  }

  # --- Opleidingsvorm check ---
  if ("opleidingsvorm" %in% ev_names && "opleidingscode_naam_opleiding" %in% ev_names) {
    opl_data <- data_ev[data_ev[["opleidingscode_naam_opleiding"]] == opleidingsnaam, ]
    if (nrow(opl_data) > 0) {
      vormen_raw <- unique(opl_data[["opleidingsvorm"]])
      vormen <- dplyr::case_when(
        vormen_raw %in% c(1, "1", "voltijd") ~ "VT",
        vormen_raw %in% c(2, "2", "deeltijd") ~ "DT",
        vormen_raw %in% c(3, "3", "duaal") ~ "DU",
        TRUE ~ as.character(vormen_raw)
      )
      if (!opleidingsvorm %in% vormen) {
        problemen <- c(problemen, paste0(
          "Opleidingsvorm '", opleidingsvorm, "' niet beschikbaar voor '",
          opleidingsnaam, "'.\n",
          "  Beschikbare vormen: ", paste(sort(unique(vormen)), collapse = ", ")
        ))
      }
    }
  }

  # --- Rapporteer ---
  if (length(problemen) > 0) {
    stop(
      "Data validatie mislukt:\n\n",
      paste(paste0("- ", problemen), collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
