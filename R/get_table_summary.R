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

# Function to create a summary table
get_table_summary <- function(df, mapping) {
  df2 <- df |>

    # Remove columns not relevant to the analysis
    dplyr::select(-c(persoonsgebonden_nummer, inschrijvingsjaar)) |>

    # Adjust the labels of Retention from True to Ja, and from False to Nee
    dplyr::mutate(retentie = forcats::fct_recode(factor(retentie), "Nee" = "0", "Ja" = "1")) |>

    # Adjust the order of the labels of Retentie
    dplyr::mutate(retentie = forcats::fct_relevel(retentie, "Ja", "Nee")) |>

    # Factor all character variables
    dplyr::mutate(dplyr::across(where(is.character), as.factor)) |>

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
