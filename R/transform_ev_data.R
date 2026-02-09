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

#' Transformeer inschrijvingsgegevens (EV-data)
#'
#' Hoofdtransformatiefunctie voor inschrijvingsgegevens. Filtert op
#' opleiding, vorm en startjaar, bepaalt retentie, telt inschrijvingen,
#' herkodeert vooropleidingen en classificeert het type aansluiting
#' (Direct, Tussenjaar, Switch, etc.).
#'
#' @param df Data frame met ruwe inschrijvingsgegevens (1CHO EV-data).
#' @param naam Character. Naam van de opleiding om op te filteren.
#' @param eoi Numeriek. Eerste jaar aan deze opleiding/instelling
#'   (minimumwaarde voor filtering).
#' @param vorm Character. Opleidingsvorm: `"VT"` (voltijd), `"DT"`
#'   (deeltijd) of `"DU"` (duaal).
#' @param dec_vopl Data frame met decodering van vooropleidingscodes.
#'   Moet de kolommen `code_vooropleiding` en
#'   `omschrijving_vooropleiding` bevatten.
#' @param dec_isat Data frame met decodering van ISAT-codes.
#'
#' @return Een data frame met getransformeerde inschrijvingsgegevens,
#'   inclusief `retentie`, `aantal_inschrijvingen`, `vooropleiding`,
#'   `aansluiting` en diverse hulpvariabelen.
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr left_join filter group_by mutate ungroup inner_join
#'   summarize across case_when pull
#' @export
transform_ev_data <- function(df, naam, eoi, vorm, dec_vopl, dec_isat) {
  ## Determine variable aantal_inschrijvingen
  mutate_aantal_inschrijvingen <- function(df, df_full) {
    students <- unique(dplyr::pull(df, persoonsgebonden_nummer))
    
    df_full |>
      
      dplyr::filter(persoonsgebonden_nummer %in% students) |>
      
      dplyr::group_by(persoonsgebonden_nummer, inschrijvingsjaar) |>
      
      dplyr::summarize(aantal_inschrijvingen = n()) |>
      
      dplyr::ungroup() |>
      
      dplyr::inner_join(df)
    
  }
  
  recode_vooropleiding <- function(df, dec_vopl) {
    cols_vo <- c(
      "hoogste_vooropleiding_voor_het_ho",
      "hoogste_vooropleiding_binnen_het_ho",
      "hoogste_vooropleiding"
    )
    
    mapping <- setNames(dec_vopl$omschrijving_vooropleiding,
                        dec_vopl$code_vooropleiding)
    
    df <- df |>
      dplyr::mutate(dplyr::across(
        dplyr::all_of(cols_vo),
        ~ dplyr::recode(as.character(.x), !!!mapping, .default = as.character(.x))
      ))
    
    
    return(df)
    
  }
  
  df <- janitor::clean_names(df)
  
  df_selection <- df |>
    
    dplyr::left_join(dec_isat) |>
    
    ## Recode opleidingsvorm
    dplyr::mutate(dplyr::across(
      opleidingsvorm,
      ~ dplyr::case_when(. == 1 ~ "VT", . == 2 ~ "DT", . == 3 ~ "DU", TRUE ~ as.character(.))
    )) |>
    
    ## Filter
    dplyr::filter(
      naam_opleiding == naam,
      eerste_jaar_aan_deze_opleiding_instelling >= eoi,
      opleidingsvorm == vorm
    )
  
  ## Split this proces such that only relevant students are selected and safe time
  df_selection |>
    
    dplyr::group_by(persoonsgebonden_nummer) |>
    
    dplyr::mutate(retentie = any(
      inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling + 1
    )) |>
    
    dplyr::ungroup() |>
    
    dplyr::filter(inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling) |>
    
    ## Create variable aantal_inschrijvingen
    mutate_aantal_inschrijvingen(df) |>
    
    ## Create variable dubbele studie
    dplyr::mutate(dubbele_studie = ifelse(aantal_inschrijvingen > 1, TRUE, FALSE)) |>
    
    ## Make postcode integer
    dplyr::mutate(dplyr::across(postcodecijfers_student_op_1_oktober, ~ as.integer(.))) |>
    
    recode_vooropleiding(dec_vopl) |>
    
    dplyr::mutate(
      vooropleiding = dplyr::case_when(
        grepl("^vwo", hoogste_vooropleiding) ~ "VWO",
        grepl("^wo|^hbo", hoogste_vooropleiding) ~ "HO",
        grepl("^mbo", hoogste_vooropleiding) ~ "MBO",
        grepl("^havo", hoogste_vooropleiding) ~ "HAVO",
        grepl("buitenlands diploma", hoogste_vooropleiding) ~ "BD",
        grepl("coll.doc.", hoogste_vooropleiding) ~ "CD",
        grepl("^overig", hoogste_vooropleiding) ~ "Overig",
        TRUE ~ "Onbekend"
      )
    ) |>
    dplyr::mutate(
      # Zorg dat jaarvelden numeriek zijn
      inschrijvingsjaar                  = as.integer(inschrijvingsjaar),
      diplomajaar_hoogste_vooropleiding  = as.integer(diplomajaar_hoogste_vooropleiding),
      eerste_jaar_in_het_hoger_onderwijs = as.integer(eerste_jaar_in_het_hoger_onderwijs),
      eerste_jaar_aan_deze_instelling    = as.integer(eerste_jaar_aan_deze_instelling)
      
    ) |>
    dplyr::mutate(
      # 2e studie: neveninschrijving in continu-domein HO
      # (code 2 = echte neveninschrijving)
      is_2e_studie =
        as.character(soort_inschrijving_continu_hoger_onderwijs) == "2",
      
      # Na CD / 21+ op basis van hoogste vooropleiding vÃ³Ã³r HO
      is_na_cd = vooropleiding == "CD",
      
      # Heeft eerder HO-jaar dan de huidige inschrijving?
      indicatie_eerstejaars_type = indicatie_eerstejaars_continu_type_ho_binnen_ho %in% c(1, 3),
      
      # Externe switch:
      # eerder HO, maar eerste jaar aan deze instelling is gelijk aan huidig inschrijvingsjaar
      # => eerder elders gezeten, nu nieuwe instelling
      is_externe_switch =
        !indicatie_eerstejaars_type &
        !is.na(eerste_jaar_aan_deze_instelling) &
        eerste_jaar_aan_deze_instelling == inschrijvingsjaar,
      
      # Interne switch:
      # eerder HO Ã©n eerder jaar aan deze instelling dan huidig inschrijvingsjaar
      # => eerder andere opleiding binnen dezelfde instelling
      is_interne_switch =
        !indicatie_eerstejaars_type &
        !is.na(eerste_jaar_aan_deze_instelling) &
        eerste_jaar_aan_deze_instelling < inschrijvingsjaar
    ) |>
    dplyr::mutate(
      aansluiting = dplyr::case_when(
        # 1) 2e studie (simultane inschrijving)
        is_2e_studie ~ "2e Studie",
        
        # 2) Na CD / 21+
        is_na_cd ~ "Na CD",
        
        # 3) Directe instroom:
        # diplomajaar = inschrijvingsjaar - 1 (diploma-jaar (T) â†’ instroomjaar T+1)!is.na(diplomajaar_hoogste_vooropleiding) &
        indicatie_eerstejaars_type & diplomajaar_hoogste_vooropleiding == (inschrijvingsjaar - 1L) ~ "Direct",
        
        # 4) Tussenjaar:
        # diplomajaar < inschrijvingsjaar - 1!is.na(diplomajaar_hoogste_vooropleiding) &
        indicatie_eerstejaars_type & diplomajaar_hoogste_vooropleiding < (inschrijvingsjaar - 1L) ~ "Tussenjaar",
        
        # 5) Externe switch
        is_externe_switch ~ "Switch extern",
        
        # 6) Interne switch
        is_interne_switch ~ "Switch intern",
        
        # 7) Onbekend: echt geen bruikbare info over vooropleiding
        vooropleiding == "Onbekend" ~ "Onbekend",
        
        # 8) Rest valt in 'Overig'
        TRUE ~ "Overig"
      ),
      aansluiting = factor(
        aansluiting,
        levels = c(
          "Direct",
          "Tussenjaar",
          "Switch intern",
          "Switch extern",
          "2e Studie",
          "Na CD",
          "Overig",
          "Onbekend"
        )
      )
    )
  
  
  
}
