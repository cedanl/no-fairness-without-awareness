## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## get_table_summary.R ####
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

library(gtsummary)
library(flextable)

#' Maak een samenvattingstabel van studentkenmerken versus retentie
#'
#' Genereert een opgemaakte flextable met descriptieve statistieken per
#' variabele, uitgesplitst naar retentie (Ja/Nee). Bevat p-waarden,
#' Bonferroni-gecorrigeerde q-waarden en significantiesterren.
#'
#' @param df Data frame met studentgegevens. Moet de kolommen `retentie`,
#'   `persoonsgebonden_nummer` en `inschrijvingsjaar` bevatten.
#' @param mapping Data frame met kolommen `Variable` (originele namen) en
#'   `Newname` (nieuwe weergavenamen).
#'
#' @return Een [flextable::flextable()]-object met de samenvattingstabel.
#'
#' @importFrom gtsummary tbl_summary modify_header modify_spanning_header
#'   bold_labels add_p add_q add_significance_stars add_overall
#'   as_flex_table style_pvalue all_continuous all_categorical
#' @importFrom flextable border set_table_properties
#' @importFrom forcats fct_recode fct_relevel
#' @importFrom dplyr select mutate across rename rename_with where
#' @importFrom stringr str_replace_all str_to_title
#' @export
get_table_summary <- function(df, mapping) {
  df2 <- df |>
    
    # Remove columns not relevant to the analysis
    select(-c(persoonsgebonden_nummer, inschrijvingsjaar)) |>
    
    # Adjust the labels of Retention from True to Ja, and from False to Nee
    mutate(retentie = forcats::fct_recode(factor(retentie), "Nee" = "0", "Ja" = "1")) |>
    
    # Adjust the order of the labels of Retentie
    mutate(retentie = forcats::fct_relevel(retentie, "Ja", "Nee")) |>
    
    # Factor all character variables
    mutate(across(where(is.character), as.factor)) |>
    
    rename(!!!setNames(mapping$Variable, mapping$Newname)) |>
    
    rename_with( ~ .x |>
                   stringr::str_replace_all("_", " ") |>
                   stringr::str_to_title())
  
  df_summary <- df2 |>
    
    tbl_summary(
      by = Retentie,
      statistic = list(
        all_continuous() ~ "{mean} ({sd})",
        all_categorical() ~ "{n} ({p}%)"
      ),
      digits = all_continuous() ~ 2,
      missing = "no",
      percent = "row"
    ) |>
    
    # Organize the design of the table
    modify_header(all_stat_cols() ~ "**{level}**, N={n} ({style_percent(p)}%)") |>
    modify_spanning_header(c("stat_1", "stat_2") ~ "**Retentie**") |>
    modify_header(label = "**Variabele**") |>
    bold_labels() |>
    #modify_caption("**Studentkenmerken versus Retentie**") |>
    add_p(
      pvalue_fun = ~ style_pvalue(.x, digits = 2),
      test.args = list(
        all_tests("fisher.test") ~ list(simulate.p.value = TRUE),
        all_tests("wilcox.test") ~ list(exact = FALSE)
      )
    ) |>
    add_q(method = "bonferroni",
          pvalue_fun = ~ style_pvalue(.x, digits = 2)) |>
    add_significance_stars(hide_p = FALSE, pattern = "{q.value}{stars}") |>
    add_overall(last = TRUE, col_label = "**Totaal**, N = {N}") |>
    as_flex_table() |>
    flextable::border(border.top = officer::fp_border(color = "grey")) |>
    set_table_properties(width = 0.8, layout = "autofit")
  
  df_summary
  
}

#' Maak een samenvattingstabel voor fairness-variabelen
#'
#' Genereert een opgemaakte flextable met descriptieve statistieken voor
#' enkel de sensitieve variabelen, uitgesplitst naar retentie na 1 jaar.
#'
#' @param df Data frame met studentgegevens. Moet de kolom `retentie` en
#'   de in `sensitive_variables` genoemde kolommen bevatten.
#' @param mapping Data frame met kolommen `Variable` (originele namen) en
#'   `Newname` (nieuwe weergavenamen).
#' @param sensitive_variables Character vector met namen van sensitieve
#'   variabelen.
#'
#' @return Een [flextable::flextable()]-object met de samenvattingstabel.
#'
#' @importFrom gtsummary tbl_summary add_p add_significance_stars
#'   add_overall add_n modify_header modify_spanning_header bold_labels
#'   as_flex_table style_pvalue
#' @importFrom flextable border set_table_properties
#' @importFrom dplyr select rename rename_with mutate all_of
#' @export
get_table_summary_fairness <- function(df, mapping, sensitive_variables) {
  df |>
    rename(!!!setNames(mapping$Variable, mapping$Newname)) |>
    select(retentie, all_of(sensitive_variables)) |>
    rename_with( ~ .x |>
                   stringr::str_replace_all("_", " ") |>
                   stringr::str_to_title()) |>
    mutate(Retentie = ifelse(Retentie == 1, "Ja", "Nee")) |>
    tbl_summary(by = Retentie) |>
    add_p(
      pvalue_fun = ~ style_pvalue(.x, digits = 2),
      test.args = list(
        all_tests("fisher.test") ~ list(simulate.p.value = TRUE),
        all_tests("wilcox.test") ~ list(exact = FALSE)
      )
    ) |>
    add_significance_stars(hide_p = FALSE, pattern = "{p.value}{stars}") |>
    add_overall(col_label = "**Totaal**  \nN = {style_number(N)}") |>
    add_n() |>
    modify_header(label ~ "**Variabele**") |>
    modify_spanning_header(c("stat_1", "stat_2") ~ "**Retentie na 1 jaar**") |>
    bold_labels() |>
    as_flex_table() |>
    flextable::border(border.top = officer::fp_border(color = "grey")) |>
    set_table_properties(width = 0.8, layout = "autofit")
  
}
