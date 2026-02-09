# Function to create the flextable for fairness analysis
get_ft_fairness <- function(ft, colors_default, with_extra = FALSE) {
  color_bias_positive <- colors_default[["color_bias_positive"]] # "#9DBF9E"
  color_bias_negative <- colors_default[["color_bias_negative"]] # "#A84268"
  color_bias_neutral  <- colors_default[["color_bias_neutral"]]  # "#FCB97D"
  color_bias_none     <- colors_default[["color_bias_none"]]     # "#E5E5E5"

  # Merge the 'Variable' column for visual grouping
  # Apply conditional formatting
  ft <- ft |>
    flextable::merge_v(j = ~ Variabele) |>
    flextable::fix_border_issues() |>
    flextable::theme_vanilla() |>
    flextable::set_header_labels(
      Variabele = "Variabele",
      Groep = "Groep",
      N = "N",
      Perc = "%",
      Bias = "Bias",
      `Geen Bias` = "Geen Bias",
      `Negatieve Bias` = "Negatieve Bias",
      `Positieve Bias` = "Positieve Bias"
    ) |>
    flextable::autofit() |>
    flextable::italic(j = 1, italic = TRUE, part = "body") |>
    flextable::color(
      i = ~ `Negatieve Bias` > 1,
      j = c("Groep", "Bias", "Negatieve Bias"),
      color = "white"
    ) |>
    flextable::color(
      i = ~ `Positieve Bias` > 1,
      j = c("Groep", "Bias", "Positieve Bias"),
      color = "white"
    ) |>
    flextable::bg(
      i = ~ `Negatieve Bias` > 1,
      j = c("Groep", "Bias", "Negatieve Bias"),
      bg = color_bias_negative
    ) |>
    flextable::bg(
      i = ~ `Positieve Bias` > 1,
      j = c("Groep", "Bias", "Positieve Bias"),
      bg = color_bias_positive
    ) |>
    flextable::bg(
      i = ~ `Negatieve Bias` > 1 & `Positieve Bias` > 1,
      j = c("Groep", "Bias"),
      bg = color_bias_neutral
    ) |>
    flextable::bg(
      i = ~ N < 15 & (`Negatieve Bias` > 1 | `Positieve Bias` > 1),
      j = c("Groep", "Bias"),
      bg = color_bias_neutral
    ) |>
    flextable::bg(
      i = ~ `Geen Bias` == 0 &
        `Positieve Bias` == 0 & `Negatieve Bias` == 0,
      j = 2:8,
      bg = color_bias_none
    ) |>
    flextable::bold(i = ~ `Negatieve Bias` > 1,
         j = c("Groep", "Bias", "Negatieve Bias")) |>
    flextable::bold(i = ~ `Positieve Bias` > 1,
         j = c("Groep", "Bias", "Positieve Bias")) |>
    flextable::valign(j = 1, valign = "top", part = "all") |>
    flextable::align_text_col(align = "left") |>
    flextable::align_nottext_col(align = "center") |>

    # Align % and Bias column
    flextable::align(j = 4:5,
          align = "center",
          part = "header") |>
    flextable::align(j = 4:5, align = "center")

  if(with_extra == FALSE) {
    ft <- flextable::delete_columns(ft, c("Geen Bias", "Negatieve Bias", "Positieve Bias", "Perc", "N")) |>

      # 3. Only now do vertical merge + valign on Variabele
      flextable::merge_v(j = "Variabele") |>
      flextable::valign(j = "Variabele", valign = "top", part = "all")
  }
  
  ft
}
