## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## add_apcg.R ####
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


add_apcg <- function(dfapcg, df1cho) {

  dfapcg <- janitor::clean_names(dfapcg)

  df1cho |>
    ## Join APCG with 1CHO
    left_join(dfapcg, by = c("postcodecijfers_student_op_1_oktober" = "cbs_apcg_pc4")) |>

    ## Coalesce FALSE with variable for APCG
    mutate(cbs_apcg_tf = as.numeric(coalesce(cbs_apcg_tf, FALSE))) |>
    
    ## Make postcode integer
    mutate(across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))

}

