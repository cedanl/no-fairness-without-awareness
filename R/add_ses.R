#' Voeg SES-data toe aan een dataset
#'
#' Koppelt sociaaleconomische status (SES) gegevens van het CBS aan een
#' studentdataset op basis van 4-cijferig postcodegebied. Per postcode wordt
#' het meest recente verslagjaar geselecteerd.
#'
#' @param df Data frame met studentgegevens. Moet de kolom
#'   `postcodecijfers_student_op_1_oktober` bevatten.
#' @param dfses Data frame met SES-gegevens per postcode. Moet de kolommen
#'   `ses_pc4` en `ses_verslagjaar` bevatten.
#'
#' @return Een data frame met dezelfde structuur als `df`, aangevuld met
#'   SES-kolommen en `postcodecijfers_student_op_1_oktober` als integer.
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr left_join mutate across group_by slice_max ungroup
#' @keywords internal
add_ses <- function(df, dfses) {
  
  dfses <- dfses |>
    
    janitor::clean_names() |>
    
    ## Remove doubles and choose only one year (2022)
    dplyr::group_by(ses_pc4) |>
    
    dplyr::slice_max(ses_verslagjaar) |>
    
    dplyr::ungroup() 
  
  df <- df |>
    
    dplyr::left_join(dfses, by = c("postcodecijfers_student_op_1_oktober" = "ses_pc4")) |>
    
    ## Make postcode integer
    dplyr::mutate(dplyr::across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))
  
    
}
