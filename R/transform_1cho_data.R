#' Koppel vakcijfers aan 1CHO-studentgegevens
#'
#' Voegt vakcijferdata samen met de studentgegevens op basis van
#' persoonsgebonden nummer. Converteert datumvelden naar Date-objecten,
#' character-variabelen naar factors, logische variabelen naar integers
#' en berekent het aantal dagen tussen inschrijving en 1 september.
#'
#' @param df Data frame met 1CHO-studentgegevens. Moet de kolommen
#'   `persoonsgebonden_nummer`, `datum_inschrijving` en
#'   `inschrijvingsjaar` bevatten.
#' @param df_vak Data frame met vakcijfers. Moet de kolom
#'   `persoonsgebonden_nummer` bevatten.
#'
#' @return Een data frame met de gecombineerde en getransformeerde data,
#'   inclusief de nieuwe kolom `dagen_tussen_inschrijving_1_september`.
#'
#' @importFrom dplyr left_join mutate across starts_with where
#' @keywords internal
transform_1cho_data <- function(df, df_vak) {


  df <- df |>
    dplyr::left_join(
      df_vak,
      by = c("persoonsgebonden_nummer" = "persoonsgebonden_nummer"),
      relationship = "many-to-one"
    )

  df <- df |>

    dplyr::mutate(dplyr::across(dplyr::starts_with("datum"), ~as.Date(as.character(.x), format = "%Y%m%d"))) |>

    # Convert character variables to factor
    dplyr::mutate(dplyr::across(dplyr::where(is.character), as.factor)) |>

    # Convert logical variables to 0 or 1
    dplyr::mutate(dplyr::across(dplyr::where(is.logical), as.integer)) |>

    ## Create variable dagen_tussen_inschrijving_1_september
    dplyr::mutate(dagen_tussen_inschrijving_1_september = as.integer(datum_inschrijving - as.Date(paste0(inschrijvingsjaar, "0901"), format = "%Y%m%d"))) 
  
  df
  
}
