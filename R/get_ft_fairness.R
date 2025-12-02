library(flextable)

# Function to create the flextable for fairness analysis
get_ft_fairness <- function(ft, colors_default, with_extra = FALSE) {
  color_bias_positive <- colors_default[["color_bias_positive"]] # "#9DBF9E"
  color_bias_negative <- colors_default[["color_bias_negative"]] # "#A84268"
  color_bias_neutral  <- colors_default[["color_bias_neutral"]]  # "#FCB97D"
  color_bias_none     <- colors_default[["color_bias_none"]]     # "#E5E5E5"
  
  # Merge the 'Variable' column for visual grouping
  # Apply conditional formatting
  ft <- ft |>
    merge_v(j = ~ Variabele) |>
    fix_border_issues() |>
    theme_vanilla() |>
    set_header_labels(
      Variabele = "Variabele",
      Groep = "Groep",
      N = "N",
      Perc = "%",
      Bias = "Bias",
      `Geen Bias` = "Geen Bias",
      `Negatieve Bias` = "Negatieve Bias",
      `Positieve Bias` = "Positieve Bias"
    ) |>
    autofit() |>
    italic(j = 1, italic = TRUE, part = "body") |>
    color(
      i = ~ `Negatieve Bias` > 1,
      j = c("Groep", "Bias", "Negatieve Bias"),
      color = "white"
    ) |>
    color(
      i = ~ `Positieve Bias` > 1,
      j = c("Groep", "Bias", "Positieve Bias"),
      color = "white"
    ) |>
    bg(
      i = ~ `Negatieve Bias` > 1,
      j = c("Groep", "Bias", "Negatieve Bias"),
      bg = color_bias_negative
    ) |>
    bg(
      i = ~ `Positieve Bias` > 1,
      j = c("Groep", "Bias", "Positieve Bias"),
      bg = color_bias_positive
    ) |>
    bg(
      i = ~ `Negatieve Bias` > 1 & `Positieve Bias` > 1,
      j = c("Groep", "Bias"),
      bg = color_bias_neutral
    ) |>
    bg(
      i = ~ N < 15 & (`Negatieve Bias` > 1 | `Positieve Bias` > 1),
      j = c("Groep", "Bias"),
      bg = color_bias_neutral
    ) |>
    bg(
      i = ~ `Geen Bias` == 0 &
        `Positieve Bias` == 0 & `Negatieve Bias` == 0,
      j = 2:8,
      bg = color_bias_none
    ) |>
    bold(i = ~ `Negatieve Bias` > 1,
         j = c("Groep", "Bias", "Negatieve Bias")) |>
    bold(i = ~ `Positieve Bias` > 1,
         j = c("Groep", "Bias", "Positieve Bias")) |>
    valign(j = 1, valign = "top", part = "all") |>
    align_text_col(align = "left") |>
    align_nottext_col(align = "center") |>
    
    # Align % and Bias column
    align(j = 4:5,
          align = "center",
          part = "header") |>
    align(j = 4:5, align = "center")
  
  if(with_extra == FALSE) {
    ft <- delete_columns(ft, c("Geen Bias", "Negatieve Bias", "Positieve Bias", "Perc", "N")) |>
      
      # 3. Only now do vertical merge + valign on Variabele
      merge_v(j = "Variabele") |>
      valign(j = "Variabele", valign = "top", part = "all")
  }
  
  ft
}
