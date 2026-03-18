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

#' Transformeer inschrijvingsgegevens (EV-data)
#'
#' Hoofdtransformatiefunctie voor inschrijvingsgegevens. Filtert op
#' opleiding, vorm en startjaar, bepaalt retentie, telt inschrijvingen,
#' classificeert de vooropleiding en het type aansluiting
#' (Direct, Tussenjaar, Switch, etc.).
#'
#' @param df Data frame met inschrijvingsgegevens (1CHO EV-data, enriched formaat).
#'   De kolom `hoogste_vooropleiding_omschrijving` moet al gevuld zijn met de
#'   gedecodeerde vooropleiding-omschrijving vanuit 1cijferho.
#' @param code Numeriek of character. Opleidingscode (ISAT-code) om op te filteren.
#' @param eoi Numeriek. Eerste jaar aan deze opleiding/instelling
#'   (minimumwaarde voor filtering).
#' @param vorm Character. Opleidingsvorm: `"VT"` (voltijd), `"DT"`
#'   (deeltijd) of `"DU"` (duaal).
#'
#' @return Een data frame met getransformeerde inschrijvingsgegevens,
#'   inclusief `retentie`, `aantal_inschrijvingen`, `vooropleiding`,
#'   `aansluiting` en diverse hulpvariabelen.
#'
#' @importFrom janitor clean_names
#' @importFrom dplyr filter group_by mutate ungroup inner_join
#'   summarize across case_when pull
#' @keywords internal
transform_ev_data <- function(df, code, eoi, vorm) {
  ## Determine variable aantal_inschrijvingen
  mutate_aantal_inschrijvingen <- function(df, df_full) {
    students <- unique(dplyr::pull(df, persoonsgebonden_nummer))

    df_full |>

      dplyr::filter(persoonsgebonden_nummer %in% students) |>

      dplyr::group_by(persoonsgebonden_nummer, inschrijvingsjaar) |>

      dplyr::summarize(aantal_inschrijvingen = dplyr::n()) |>

      dplyr::ungroup() |>

      dplyr::inner_join(df, by = c("persoonsgebonden_nummer", "inschrijvingsjaar"))

  }

  df <- janitor::clean_names(df)

  # Enriched data uses the suffix _vooropleiding; normalize to the short name
  if ("hoogste_vooropleiding_omschrijving_vooropleiding" %in% names(df) &&
      !"hoogste_vooropleiding_omschrijving" %in% names(df)) {
    df <- dplyr::rename(
      df,
      hoogste_vooropleiding_omschrijving = hoogste_vooropleiding_omschrijving_vooropleiding
    )
  }

  df_selection <- df |>

    ## Recode opleidingsvorm (enriched: "voltijd"/"deeltijd"/"duaal", legacy: 1/2/3)
    dplyr::mutate(dplyr::across(
      opleidingsvorm,
      ~ dplyr::case_when(
        . %in% c(1, "1", "voltijd") ~ "VT",
        . %in% c(2, "2", "deeltijd") ~ "DT",
        . %in% c(3, "3", "duaal") ~ "DU",
        TRUE ~ as.character(.)
      )
    )) |>

    ## Recode geslacht (enriched: "man"/"vrouw", legacy: "M"/"V")
    dplyr::mutate(dplyr::across(
      geslacht,
      ~ dplyr::case_when(
        . %in% c("M", "man")   ~ "M",
        . %in% c("V", "vrouw") ~ "V",
        TRUE ~ NA_character_
      )
    )) |>

    ## Filter on opleidingscode, eerste jaar and opleidingsvorm
    dplyr::filter(
      as.character(opleidingscode) == as.character(code),
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

    dplyr::mutate(
      ## Classify vooropleiding from already-decoded omschrijving column
      vooropleiding = dplyr::case_when(
        grepl("^vwo", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "VWO",
        grepl("^wo|^hbo", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "HO",
        grepl("^mbo", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "MBO",
        grepl("^havo", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "HAVO",
        grepl("buitenlands diploma", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "BD",
        grepl("coll\\.doc\\.", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "CD",
        grepl("^overig", hoogste_vooropleiding_omschrijving, ignore.case = TRUE) ~ "Overig",
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
      # 2e studie: echte neveninschrijving in continu-domein HO
      # enriched data bevat volledige omschrijving; legacy data gebruikt code "2"
      is_2e_studie =
        grepl("echte neveninschrijving", soort_inschrijving_continu_hoger_onderwijs, ignore.case = TRUE) |
        as.character(soort_inschrijving_continu_hoger_onderwijs) == "2",

      # Na CD / 21+ op basis van hoogste vooropleiding voor HO
      is_na_cd = vooropleiding == "CD",

      # Eerstejaars in het continu type HO?
      # enriched data bevat "eerstejaars" in de omschrijving; legacy data gebruikt codes 1 en 3
      indicatie_eerstejaars_type =
        grepl("eerstejaars", indicatie_eerstejaars_continu_type_ho_binnen_ho, ignore.case = TRUE) |
        indicatie_eerstejaars_continu_type_ho_binnen_ho %in% c(1, 3),

      # Externe switch:
      # eerder HO, maar eerste jaar aan deze instelling is gelijk aan huidig inschrijvingsjaar
      # => eerder elders gezeten, nu nieuwe instelling
      is_externe_switch =
        !indicatie_eerstejaars_type &
        !is.na(eerste_jaar_aan_deze_instelling) &
        eerste_jaar_aan_deze_instelling == inschrijvingsjaar,

      # Interne switch:
      # eerder HO en eerder jaar aan deze instelling dan huidig inschrijvingsjaar
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
        # diplomajaar = inschrijvingsjaar - 1 (diploma-jaar (T) -> instroomjaar T+1)
        !is.na(diplomajaar_hoogste_vooropleiding) &
        indicatie_eerstejaars_type & diplomajaar_hoogste_vooropleiding == (inschrijvingsjaar - 1L) ~ "Direct",

        # 4) Tussenjaar:
        # diplomajaar < inschrijvingsjaar - 1
        !is.na(diplomajaar_hoogste_vooropleiding) &
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
