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
#' @keywords internal
get_table_summary <- function(df, mapping) {
  df2 <- df |>

    # Remove columns not relevant to the analysis
    dplyr::select(-c(persoonsgebonden_nummer, inschrijvingsjaar)) |>
    
    # Adjust the labels of Retention from True to Ja, and from False to Nee
    dplyr::mutate(retentie = forcats::fct_recode(factor(retentie), "Nee" = "0", "Ja" = "1")) |>
    
    # Adjust the order of the labels of Retentie
    dplyr::mutate(retentie = forcats::fct_relevel(retentie, "Ja", "Nee")) |>
    
    # Factor all character variables
    dplyr::mutate(dplyr::across(dplyr::where(is.character), as.factor)) |>
    
    dplyr::rename(!!!setNames(mapping$Variable, mapping$Newname)) |>

    dplyr::rename_with( ~ .x |>
                   stringr::str_replace_all("_", " ") |>
                   stringr::str_to_title())

  df_summary <- df2 |>
    gtsummary::tbl_summary(
      by = Retentie,
      statistic = list(
        gtsummary::all_continuous() ~ "{mean} ({sd})",
        gtsummary::all_categorical() ~ "{n} ({p}%)"
      ),
      digits = gtsummary::all_continuous() ~ 2,
      missing = "no",
      percent = "row"
    ) |>

    # Organize the design of the table
    gtsummary::modify_header(gtsummary::all_stat_cols() ~ "**{level}**, N={n} ({gtsummary::style_percent(p)}%)") |>
    gtsummary::modify_spanning_header(c("stat_1", "stat_2") ~ "**Retentie**") |>
    gtsummary::modify_header(label = "**Variabele**") |>
    gtsummary::bold_labels() |>
    #gtsummary::modify_caption("**Studentkenmerken versus Retentie**") |>
    gtsummary::add_p(
      pvalue_fun = ~ gtsummary::style_pvalue(.x, digits = 2),
      test.args = list(
        gtsummary::all_tests("fisher.test") ~ list(simulate.p.value = TRUE),
        gtsummary::all_tests("wilcox.test") ~ list(exact = FALSE)
      )
    ) |>
    gtsummary::add_q(method = "bonferroni",
          pvalue_fun = ~ gtsummary::style_pvalue(.x, digits = 2)) |>
    gtsummary::add_significance_stars(hide_p = FALSE, pattern = "{q.value}{stars}") |>
    gtsummary::add_overall(last = TRUE, col_label = "**Totaal**, N = {N}") |>
    gtsummary::as_flex_table() |>
    flextable::border(border.top = officer::fp_border(color = "grey")) |>
    flextable::set_table_properties(width = 0.8, layout = "autofit")
  
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
#' @keywords internal
get_table_summary_fairness <- function(df, mapping, sensitive_variables) {
  df |>
    dplyr::rename(!!!setNames(mapping$Variable, mapping$Newname)) |>
    dplyr::select(retentie, dplyr::all_of(sensitive_variables)) |>
    dplyr::rename_with( ~ .x |>
                   stringr::str_replace_all("_", " ") |>
                   stringr::str_to_title()) |>
    dplyr::mutate(Retentie = ifelse(Retentie == 1, "Ja", "Nee")) |>
    gtsummary::tbl_summary(by = Retentie) |>
    gtsummary::add_p(
      pvalue_fun = ~ gtsummary::style_pvalue(.x, digits = 2),
      test.args = list(
        gtsummary::all_tests("fisher.test") ~ list(simulate.p.value = TRUE),
        gtsummary::all_tests("wilcox.test") ~ list(exact = FALSE)
      )
    ) |>
    gtsummary::add_significance_stars(hide_p = FALSE, pattern = "{p.value}{stars}") |>
    gtsummary::add_overall(col_label = "**Totaal**  \nN = {gtsummary::style_number(N)}") |>
    gtsummary::add_n() |>
    gtsummary::modify_header(label ~ "**Variabele**") |>
    gtsummary::modify_spanning_header(c("stat_1", "stat_2") ~ "**Retentie na 1 jaar**") |>
    gtsummary::bold_labels() |>
    gtsummary::as_flex_table() |>
    flextable::border(border.top = officer::fp_border(color = "grey")) |>
    flextable::set_table_properties(width = 0.8, layout = "autofit")
}
