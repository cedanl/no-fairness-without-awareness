## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## add_theme_elements.R ####
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

library(ggplot2)
library(ggtext)

source("config/colors.R")

# Function to add theme elements
add_theme_elements <- function(p,
                               title_subtitle = TRUE,
                               extended = FALSE) {
  
  # Customize theme with or without title and subtitle
  if (title_subtitle) {
    p <- p + theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_markdown(),
      axis.text.y = element_text(size = 10),
      plot.caption = element_textbox_simple(
        size = 8,
        color = colors_default["caption_color"],
        padding = margin(0, 0, 0, 0),
        margin = margin(15, 0, 0, 0)
      )
    ) 
  } else {
    p <- p + theme(
      axis.text.y = element_text(size = 10),
      plot.caption = element_textbox_simple(
        size = 8,
        color = colors_default["caption_color"],
        padding = margin(0, 0, 0, 0),
        margin = margin(15, 0, 0, 0)
      )
    )
  }
  
  # If the theme needs to be expanded, add additional elements
  if (extended) {
    
    p <- p + 
      
      # Customize the theme further
      theme(
        axis.title.x = element_text(margin = margin(t = 20))
      ) +
      
      # Adjust the position of the legend and hide the title
      theme(legend.position = "bottom",
            legend.title = element_blank()) +
      
      # Make the grid a little quieter
      theme(panel.grid.minor = element_blank()) +
      
      # Make the cups of the facets larger
      theme(strip.text = element_text(size = 12))
  }
  
  p
  
}
