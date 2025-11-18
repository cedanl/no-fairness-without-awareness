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

transform_ev_data <- function(df, naam, eoi, vorm, dec_vopl, dec_isat) {
  
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
  
  recode_vooropleiding <- function(df, dec_vopl) {
    
    cols_vo <- c("hoogste_vooropleiding_voor_het_ho",
                  "hoogste_vooropleiding_binnen_het_ho",
                  "hoogste_vooropleiding")
    
    mapping <- setNames(dec_vopl$omschrijving_vooropleiding,
                        dec_vopl$code_vooropleiding)
    
    df <- df |>
      mutate(across(
        all_of(cols_vo),
        ~ recode(as.character(.x), !!!mapping, .default = as.character(.x))
      ))
    
    
    return(df)
    
  }
  
  df <- janitor::clean_names(df)
  
  df_selection <- df |>
    
    left_join(dec_isat) |>
    
    ## Recode opleidingsvorm
    mutate(across(opleidingsvorm, ~case_when(. == 1 ~ "VT",
                                             . == 2 ~ "DT",
                                             . == 3 ~ "DU",
                                             TRUE ~ as.character(.)))) |>
    
    ## Filter
    filter(#naam_opleiding == naam,
           eerste_jaar_aan_deze_opleiding_instelling >= eoi,
           opleidingsvorm == vorm)

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
    mutate(across(postcodecijfers_student_op_1_oktober, ~as.integer(.))) |>
    
    recode_vooropleiding(dec_vopl) |>
    
    mutate(vooropleiding = case_when(grepl("^vwo", hoogste_vooropleiding) ~ "VWO",
                                     grepl("^wo|^hbo", hoogste_vooropleiding) ~ "HO",
                                     grepl("^mbo", hoogste_vooropleiding) ~ "MBO",
                                     grepl("^havo", hoogste_vooropleiding) ~ "HAVO",
                                     grepl("buitenlands diploma", hoogste_vooropleiding) ~ "BD",
                                     grepl("coll.doc.", hoogste_vooropleiding) ~ "CD",
                                     grepl("^overig", hoogste_vooropleiding) ~ "Overig",
                                     TRUE ~ "Onbekend"))
  
}
