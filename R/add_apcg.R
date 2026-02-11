#' Voeg APCG-data toe aan 1CHO-dataset
#'
#' Koppelt Armoede en Probleemwijk per 4-cijferig Postcodegebied (APCG) data
#' aan het 1CHO-studentbestand op basis van postcode. Mist een student een
#' APCG-waarde, dan wordt deze op 0 gezet.
#'
#' @param df1cho Data frame met 1CHO-studentgegevens. Moet de kolom
#'   `postcodecijfers_student_op_1_oktober` bevatten.
#' @param dfapcg Data frame met APCG-gegevens per postcode. Moet de kolommen
#'   `cbs_apcg_pc4` en `cbs_apcg_tf` bevatten.
#'
#' @return Een data frame met dezelfde structuur als `df1cho`, aangevuld met de
#'   kolom `cbs_apcg_tf` (numeriek: 0 of 1) en
#'   `postcodecijfers_student_op_1_oktober` als integer.
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr left_join mutate across coalesce
#' @export
add_apcg <- function(df1cho, dfapcg) {

  dfapcg <- janitor::clean_names(dfapcg)

  df1cho |>
    ## Join APCG with 1CHO
    dplyr::left_join(dfapcg, by = c("postcodecijfers_student_op_1_oktober" = "cbs_apcg_pc4")) |>

    ## Coalesce FALSE with variable for APCG
    dplyr::mutate(cbs_apcg_tf = as.numeric(dplyr::coalesce(cbs_apcg_tf, FALSE))) |>

    ## Make postcode integer
    dplyr::mutate(dplyr::across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))

}

