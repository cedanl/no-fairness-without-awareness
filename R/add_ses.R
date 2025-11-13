## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## add_ses.R ####
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

add_ses <- function(df, dfses) {
  
  dfses <- dfses |>
    
    janitor::clean_names() |>
    
    ## Remove doubles and choose only one year (2022)
    group_by(ses_pc4) |>
    
    slice_max(ses_verslagjaar) |>
    
    ungroup() 
  
  df <- df |>
    
    left_join(dfses, by = c("postcodecijfers_student_op_1_oktober" = "ses_pc4")) |>
    
    ## Make postcode integer
    mutate(across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))
  
  ## Fill in NA with mean
  
    
}
