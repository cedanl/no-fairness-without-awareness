## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## create_fairness_plot.R ####
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

#' Maak een fairness-check plot
#'
#' Genereert een staafdiagram met fairness-metrieken op basis van een
#' fairness-object. Het plot toont de verhouding van metrieken per subgroep
#' ten opzichte van de geprivilegieerde groep. Het plot wordt opgeslagen als
#' PNG-bestand in de `output/` map.
#'
#' @param fairness_object Een fairness-object aangemaakt met
#'   [fairmodels::fairness_check()].
#' @param group Character. Naam van de groepsvariabele (bijv. `"geslacht"`).
#' @param privileged Character. Naam van de geprivilegieerde
#'   (referentie)groep.
#' @param colors_default Named list met standaardkleuren. Moet minstens
#'   `positive_color` en `background_color` bevatten.
#' @param n_categories Numeriek. Aantal categorieen minus 1, gebruikt voor
#'   het berekenen van de plothoogte.
#' @param caption Character of `NULL`. Optioneel onderschrift voor het plot.
#'
#' @return Onzichtbaar. Het plot wordt opgeslagen als
#'   `temp/fairness_plot_\{group\}.png`.
#'
#' @importFrom ggplot2 ggsave theme_minimal scale_fill_manual
#'   scale_y_continuous theme element_blank element_text element_rect
#' @importFrom glue glue
#' @importFrom ragg agg_png
#' @keywords internal
create_fairness_plot <- function(fairness_object,
                                 group,
                                 privileged,
                                 colors_default,
                                 n_categories,
                                 caption = NULL) {
  # Determine the y axis
  y_breaks <- seq(-100, 100, by = 0.2)
  
  # Create a fairness plot
  fairness_plot <- fairness_object |>
    plot() +
    ggplot2::theme_minimal() +
    set_theme() +
    
    # Add title and subtitle
    ggplot2::labs(
      title = "Fairness check",
      subtitle = glue::glue(
        "Fairness van het model voor **{stringr::str_to_title(group)}** ",
        "ten opzichte van **{privileged}**"
      ),
      caption = caption,
      x = NULL,
      y = NULL
    )
  
  # Remove the existing color scale,
  # so there is no warning about the existing color scale
  fairness_plot$scales$scales <- list()
  
  # Build the plot further
  fairness_plot <- fairness_plot +
    
    # Define the color
    ggplot2::scale_fill_manual(values = c(colors_default[["positive_color"]])) +
    
    # Adjust the y-axis scale
    ggplot2::scale_y_continuous(breaks = y_breaks)
  
  # Add elements.
  fairness_plot <- add_theme_elements(fairness_plot, colors_default, title_subtitle = TRUE) +
    
    # Customize some theme elements
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "none",
      strip.text = ggplot2::element_text(hjust = 0),
      panel.border = ggplot2::element_rect(
        colour = "darkgrey",
        fill   = NA,
        size   = 0.4
      )
    )
  
  ggplot2::ggsave(
    filename  = glue::glue("temp/fairness_plot_{group}.png"),
    plot      = fairness_plot,
    height    = (250 + (50 * n_categories)) / 72,
    width     = 640 / 72,
    bg        = colors_default[["background_color"]],
    device    = ragg::agg_png,
    res       = 300,
    create.dir = TRUE
  )
  
}
