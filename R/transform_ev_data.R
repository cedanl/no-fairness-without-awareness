## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## tarnsform_ev_data.R ####
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

transform_ev_data <- function(df, opleidingscode, eoi, opleidingsvorm) {
  
  ## Determine variable aantal_inschrijvingen
  mutate_aantal_inschrijvingen <- function(df, df_full) {
    
    students <- unique(pull(df, persoonsgebonden_nummer))
    
    df_full |>
      
      filter(persoonsgebonden_nummer %in% students) |>
      
      group_by(persoonsgebonden_nummer, inschrijvingsjaar) |>
      
      summarize(aantal_inschrijvingen = n()) |>
      
      ungroup() |>
      
      inner_join(df)
    
  }
  
  df <- janitor::clean_names(df)
  
  df_selection <- df |>
    
    ## Recode opleidingsvorm
    mutate(across(opleidingsvorm, ~case_when(. == 1 ~ "VT",
                                             . == 2 ~ "DT",
                                             . == 3 ~ "DU",
                                             TRUE ~ as.character(.)))) |>
    
    ## Filter
    filter(opleidingscode == opleidingscode,
           eerste_jaar_aan_deze_instelling >= eoi,
           opleidingsvorm == opleidingsvorm)
  
  ## Split this proces such that only relevant students are selected and safe time
  df_selection |>
    
    group_by(persoonsgebonden_nummer) |>
    
    mutate(retentie = any(inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling + 1)) |>
    
    ungroup() |>
    
    filter(inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling) |>
    
    ## TODO: TEMP
    filter(inschrijvingsjaar < 2023) |>
    
    ## Create variable aantal_inschrijvingen
    mutate_aantal_inschrijvingen(df) |>
    
    ## Create variable dubbele studie
    mutate(dubbele_studie = ifelse(aantal_inschrijvingen > 1, TRUE, FALSE)) |>
    
    ## Make postcode integer
    mutate(across(postcodecijfers_student_op_1_oktober, ~as.integer(.)))
  
}
