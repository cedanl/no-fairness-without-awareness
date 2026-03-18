## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 02_transform_data.R ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
## Verspreiding buiten De HHs: Nee
##
## Doel: Doel
##
## Afhankelijkheden: Afhankelijkheid
##
## Datasets: Datasets
##
## Opmerkingen:
## 1) Geen.
## 2) ___
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' Voer de volledige datatransformatie-pipeline uit
#'
#' Orchestreert de transformatie van ruwe 1CHO-data naar een
#' analyse-klaar data frame. Combineert inschrijvingsgegevens,
#' vakcijfers, APCG- en SES-data, maakt missing-indicatoren aan
#' en imputeert ontbrekende numerieke waarden met het gemiddelde.
#'
#' @param metadata Named list met metadatabestanden, zoals geretourneerd
#'   door [read_metadata()].
#' @param opleidingscode Numeriek of character. ISAT-opleidingscode om op te
#'   filteren (bijv. `60048`).
#' @param opleidingsvorm Character. Opleidingsvorm (`"VT"`, `"DT"` of
#'   `"DU"`).
#' @param eoi Numeriek. Eerste jaar aan deze opleiding/instelling
#'   (minimumwaarde).
#' @param data_ev Data frame met 1CHO-inschrijvingsgegevens (EV-bestand, enriched formaat).
#' @param data_vakhavw Data frame met 1CHO-vakcijfergegevens
#'   (VAKHAVW-bestand).
#'
#' @return Een data frame met getransformeerde en geimputeerde data,
#'   gefilterd op de in metadata gedefinieerde variabelen.
#'
#' @importFrom dplyr mutate across select all_of where
#' @export
transform_data <- function(metadata,
                           opleidingscode,
                           opleidingsvorm,
                           eoi,
                           data_ev,
                           data_vakhavw) {

  dfapcg <- metadata$dfapcg
  dfses <- metadata$dfses
  variables <- metadata$variables


  #-------------------------------------------------------------------
  # Transform
  #-------------------------------------------------------------------
  data_ev <- transform_ev_data(
    data_ev,
    code = opleidingscode,
    eoi  = eoi,
    vorm = opleidingsvorm
  )

  data_vakhavw <- transform_vakhavw(data_vakhavw)

  dfcyfer <- transform_1cho_data(data_ev, data_vakhavw)

  #-------------------------------------------------------------------
  # Add APCG & SES + basic cleaning
  #-------------------------------------------------------------------

  vars <- c("netl", "entl", "nat", "wis")
  df <- dfcyfer |>
    
    add_apcg(dfapcg) |>
    
    add_ses(dfses) |>
    
    dplyr::mutate(dplyr::across(all_of(vars), ~ ifelse(is.na(.x), 1, 0), .names = "{.col}_missing")) |>
    # Select variables used in the model
    dplyr::select(dplyr::all_of(variables)) |>
    # Impute all numeric variables with the mean
    dplyr::mutate(dplyr::across(where(is.numeric), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x))) 
  
  return(df)
}
