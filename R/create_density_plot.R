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

library(ggplot2)
library(glue)

source("R/set_theme.R")
source("R/add_theme_elements.R")

# Function to create a density plot
create_density_plot <- function(fairness_object, group, caption, colors_default, colors_list) {
  
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
    .values <- color_list[[group]]
  }
  
  # Create a density plot
  density_plot <- fairness_object |> 
    
    fairmodels::plot_density() +
    
    # Add title and subtitle
    labs(
      title = glue(
        "Verdeling en dichtheid van retentie"
      ),
      subtitle = glue("Naar **{stringr::str_to_title(group)}**"),
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
    scale_fill_manual(
      name = NULL,
      values = .values
    ) +
    
    # Adjust the x-axis scale
    scale_x_continuous(breaks = x_axis_list[["x_breaks"]],
                       labels = x_axis_list[["x_labels"]],
                       limits = c(0, 1)) +
    
    # Add a line on the 50% labeled “50%”
    geom_vline(xintercept = 0.5,
               linetype = "dotted",
               color = colors_default[["positive_color"]]) +
    
    # Add the label “50%”
    annotate(
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
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "none",
      strip.text = element_blank()
    )
  
  # Add elements.
  density_plot <- add_theme_elements(density_plot,
                                     title_subtitle = TRUE) +
    theme(legend.position = "bottom",
          legend.title = element_blank()) +
    guides(fill = guide_legend(nrow = 1))
  
  
  density_plot
  
}
