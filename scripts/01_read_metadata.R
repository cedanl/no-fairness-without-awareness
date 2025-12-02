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
library(dplyr)

read_metadata <- function() {

  dfapcg <- read.table("metadata/APCG_2019.csv", sep = ";", header = TRUE)
  
  dfses <- read.table(
    "metadata/SES_PC4_2021-2022.csv",
    sep = ";",
    header = TRUE,
    dec = ","
  )
  
  df_variables <- readxl::read_xlsx("metadata/variabelen.xlsx")
  
  variables <- df_variables |>
    dplyr::filter(Used) |>
    dplyr::pull(Variable)
  
  sensitive_variables <- df_variables |>
    dplyr::filter(Sensitive) |>
    dplyr::pull(Variable)
  
  mapping_newname <- df_variables |>
    dplyr::select(Variable, Newname) |>
    tidyr::drop_na()
  
  df_levels <- readxl::read_xlsx("metadata/levels.xlsx") |>
    dplyr::group_by(VAR_Formal_variable) |>
    dplyr::arrange(VAR_Level_order, .by_group = TRUE) |>
    dplyr::ungroup()
  
  dec_vopl <- read.csv("metadata/dec/Dec_vopl.csv", sep = "|") |>
    janitor::clean_names()
  
  dec_isat <- read.csv("metadata/dec/Dec_isat.csv", sep = "|") |>
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
