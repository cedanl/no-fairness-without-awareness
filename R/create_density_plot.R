## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## create_density_plot.R ####
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

#' Maak een dichtheidsplot voor fairness-analyse
#'
#' Genereert een dichtheidsplot op basis van een fairness-object dat de
#' verdeling van retentie-voorspellingen toont, opgesplitst per groep.
#' Het plot wordt opgeslagen als PNG-bestand in de `output/` map.
#'
#' @param fairness_object Een fairness-object aangemaakt met
#'   [fairmodels::fairness_check()].
#' @param group Character. Naam van de groepsvariabele (bijv. `"geslacht"`)
#'   of `"all"` voor een enkele kleur.
#' @param caption Character. Onderschrift voor het plot.
#' @param colors_default Named list met standaardkleuren. Moet minstens
#'   `metrics_blue`, `positive_color` en `background_color` bevatten.
#' @param colors_list Named list met kleurvectoren per groepsvariabele.
#' @param n_categories Numeriek. Aantal categorieen minus 1, gebruikt voor
#'   het berekenen van de plothoogte.
#' @param var Character. Naam van de variabele (voor bestandsnaam).
#'
#' @return Onzichtbaar. Het plot wordt opgeslagen als
#'   `temp/fairness_density_\{group\}.png`.
#'
#' @importFrom ggplot2 ggsave scale_fill_manual scale_x_continuous geom_vline
#'   annotate theme element_blank guides guide_legend
#' @importFrom glue glue
#' @importFrom fairmodels plot_density
#' @importFrom ragg agg_png
#' @export
create_density_plot <- function(fairness_object,
                                group,
                                caption,
                                colors_default,
                                colors_list,
                                n_categories,
                                var) {
  set_xy_axis <- function(axis, breaks = 4) {
    if (axis == "x") {
      x_axis_list <- list()
      x_axis_list[["x_breaks"]] <- seq(0, 1, by = (1 / breaks))
      x_axis_list[["x_labels"]] <- paste0(seq(0, 100, by = (100 / breaks)), "%")
      
      x_axis_list
    }
    
    if (axis == "y") {
      y_axis_list <- list()
      y_axis_list[["y_breaks"]] <- seq(0, 1, by = 0.25)
      y_axis_list[["y_labels"]] <- paste0(seq(0, 100, by = 25), "%")
      
      y_axis_list
    }
    
  }
  
  # Determine the x axis
  x_axis_list <- set_xy_axis(axis = "x")
  
  # Define color scales for each variable
  if (group == "all") {
    .values <- colors_default[["metrics_blue"]]
  } else {
    .values <- colors_list[[group]]
  }
  
  # Create a density plot
  density_plot <- fairness_object |>

    fairmodels::plot_density() +

    # Add title and subtitle
    ggplot2::labs(
      title = glue::glue("Verdeling en dichtheid van retentie"),
      subtitle = glue::glue("Naar **{stringr::str_to_title(group)}**"),
      caption = caption,
      x = NULL,
      y = NULL
    )

  # Remove the existing color scale,
  # so there is no warning about the existing color scale
  density_plot$scales$scales <- list()

  # Define the color
  density_plot <- density_plot +

    # Add a single scale for the fill
    ggplot2::scale_fill_manual(name = NULL, values = .values) +

    # Adjust the x-axis scale
    ggplot2::scale_x_continuous(breaks = x_axis_list[["x_breaks"]],
                       labels = x_axis_list[["x_labels"]],
                       limits = c(0, 1)) +

    # Add a line on the 50% labeled "50%"
    ggplot2::geom_vline(xintercept = 0.5,
               linetype = "dotted",
               color = colors_default[["positive_color"]]) +

    # Add the label "50%"
    ggplot2::annotate(
      "text",
      x = 0.53,
      y = 0.5,
      label = "50%",
      vjust = -0.3,
      color = colors_default[["positive_color"]]
    ) +

    # Apply the theme
    set_theme()  +

    # Customize some theme elements
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "none",
      strip.text = ggplot2::element_blank()
    )

  # Add elements.
  density_plot <- add_theme_elements(density_plot, colors_default, title_subtitle = TRUE) +
    ggplot2::theme(legend.position = "bottom", legend.title = ggplot2::element_blank()) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 1))
  
  ggplot2::ggsave(
    filename  = glue::glue("temp/fairness_density_{group}.png"),
    plot      = density_plot,
    height    = (250 + (50 * n_categories)) / 72,
    width     = 640 / 72,
    bg        = colors_default[["background_color"]],
    device    = ragg::agg_png,
    res       = 300,
    create.dir = TRUE
  )
  
}
