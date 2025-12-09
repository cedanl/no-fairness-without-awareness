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

# Function to create a fairness plot
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
    theme_minimal() +
    set_theme() +
    
    # Add title and subtitle
    labs(
      title = "Fairness check",
      subtitle = glue(
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
    scale_fill_manual(values = c(colors_default[["positive_color"]])) +
    
    # Adjust the y-axis scale
    scale_y_continuous(breaks = y_breaks)
  
  # Add elements.
  fairness_plot <- add_theme_elements(fairness_plot, title_subtitle = TRUE) +
    
    # Customize some theme elements
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "none",
      strip.text = element_text(hjust = 0),
      panel.border = ggplot2::element_rect(
        colour = "darkgrey",
        fill   = NA,
        size   = 0.4
      )
    )
  
  ggplot2::ggsave(
    filename  = glue::glue("output/fairness_plot_{group}.png"),
    plot      = fairness_plot,
    height    = (250 + (50 * n_categories)) / 72,
    width     = 640 / 72,
    bg        = colors_default[["background_color"]],
    device    = ragg::agg_png,
    res       = 300,
    create.dir = TRUE
  )
  
}
