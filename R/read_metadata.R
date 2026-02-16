## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 01_read_metadata.R ####
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

#' Lees alle metadata-bestanden in
#'
#' Leest de configuratie- en metadatabestanden die nodig zijn voor de
#' NFWA-analyse. Deze bestanden worden automatisch meegeleverd met het
#' package en bevatten APCG-data, SES-data, variabelendefinities,
#' sensitieve variabelen, naamgeving-mapping, level-definities en
#' decodeertabellen voor vooropleidingen en ISAT-codes.
#'
#' @details
#' De metadata wordt automatisch geïnstalleerd met het package in
#' `inst/metadata/`. Je hoeft geen eigen metadata-bestanden aan te
#' leveren - `read_metadata()` vindt de bestanden automatisch.
#'
#' Meegeleverde bestanden:
#' \itemize{
#'   \item `variabelen.xlsx` - Definitie van te gebruiken variabelen
#'   \item `levels.xlsx` - Labels voor categorische variabelen
#'   \item `APCG_2019.csv` - Armoede/probleemwijken per postcode
#'   \item `SES_PC4_2021-2022.csv` - Sociaaleconomische status per postcode
#'   \item `dec/Dec_vopl.csv` - Decodering vooropleidingscodes
#'   \item `dec/Dec_isat.csv` - Decodering ISAT-codes
#' }
#'
#' @return Een named list met de volgende elementen:
#'   \describe{
#'     \item{dfapcg}{Data frame met APCG-data per postcode.}
#'     \item{dfses}{Data frame met SES-data per postcode.}
#'     \item{variables}{Character vector met namen van te gebruiken
#'       variabelen.}
#'     \item{sensitive_variables}{Character vector met namen van
#'       sensitieve variabelen.}
#'     \item{mapping_newname}{Data frame met kolommen `Variable` en
#'       `Newname` voor hernoeming.}
#'     \item{df_levels}{Data frame met level-definities per variabele.}
#'     \item{dec_vopl}{Data frame met decodering vooropleidingscodes.}
#'     \item{dec_isat}{Data frame met decodering ISAT-codes.}
#'   }
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr filter pull select group_by arrange ungroup
#' @importFrom tidyr drop_na
#' @export
read_metadata <- function() {
  # Use system.file() to find package-installed metadata files
  dfapcg <- read.table(
    system.file("metadata", "APCG_2019.csv", package = "nfwa"),
    sep = ";",
    header = TRUE,
    dec = ","
  )
  
  dfses <- read.table(
    system.file("metadata", "SES_PC4_2021-2022.csv", package = "nfwa"),
    sep = ";",
    header = TRUE,
    dec = ","
  )
  
  df_variables <- read.table(
    system.file("metadata", "variabelen.csv", package = "nfwa"),
    sep = ";",
    header = TRUE,
    dec = ","
  )
  
  variables <- df_variables |>
    dplyr::filter(Used) |>
    dplyr::pull(Variable)
  
  sensitive_variables <- df_variables |>
    dplyr::filter(Sensitive) |>
    dplyr::pull(Variable)
  
  mapping_newname <- df_variables |>
    dplyr::select(Variable, Newname) |>
    tidyr::drop_na()
  
  df_levels <- read.table(
    system.file("metadata", "levels.csv", package = "nfwa"),
    sep = ";",
    header = TRUE,
    dec = ","
  ) |>
    dplyr::group_by(VAR_Formal_variable) |>
    dplyr::arrange(VAR_Level_order, .by_group = TRUE) |>
    dplyr::ungroup()
  
  dec_vopl <- read.csv(system.file("metadata", "dec", "Dec_vopl.csv", package = "nfwa"),
                       sep = "|") |>
    janitor::clean_names()
  
  dec_isat <- read.csv(system.file("metadata", "dec", "Dec_isat.csv", package = "nfwa"),
                       sep = "|") |>
    janitor::clean_names()
  
  return(
    list(
      dfapcg = dfapcg,
      dfses = dfses,
      variables = variables,
      sensitive_variables = sensitive_variables,
      mapping_newname = mapping_newname,
      df_levels = df_levels,
      dec_vopl = dec_vopl,
      dec_isat = dec_isat
    )
  )
  
}
