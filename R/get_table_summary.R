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

# Function to create a summary table
get_table_summary <- function(df, mapping) {
  
  df <- df |>
    
    # Remove columns not relevant to the analysis
    select(-c(persoonsgebonden_nummer, inschrijvingsjaar)) |> 
    
    # Adjust the labels of Retention from True to Ja, and from False to Nee
    mutate(retentie = forcats::fct_recode(retentie, "Nee" = "0", "Ja" = "1")) |>
    
    # Adjust the order of the labels of Retentie
    mutate(retentie = forcats::fct_relevel(retentie, "Ja", "Nee")) |> 
    
    # Factor all character variables
    mutate(across(where(is.character), as.factor)) |>
    
    rename(!!! setNames(mapping$Variable, mapping$Newname)) |>
    
    rename_with(~ .x |>
                  stringr::str_replace_all("_", " ") |>
                  stringr::str_to_title())
  
  df_summary <- df |> 
    
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
    modify_caption("**Studentkenmerken versus Retentie**") |>
    add_p(pvalue_fun = ~ style_pvalue(.x, digits = 2),
          test.args = list(
            all_tests("fisher.test") ~ list(simulate.p.value = TRUE),
            all_tests("wilcox.test") ~ list(exact = FALSE)
          )) |>
    add_q(method = "bonferroni",
          pvalue_fun = ~ style_pvalue(.x, digits = 2)) |>
    add_significance_stars(
      hide_p = FALSE,
      pattern = "{q.value}{stars}"
    ) |>
    add_overall(last = TRUE, col_label = "**Totaal**, N = {N}") |>
    as_flex_table() |>
    flextable::border(border.top = officer::fp_border(color = "grey")) |>
    set_table_properties(width = 0.8, layout = "autofit")
  
  df_summary
  
}
