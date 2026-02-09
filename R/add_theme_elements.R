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

#' Voeg thema-elementen toe aan een ggplot
#'
#' Past aanvullende thema-instellingen toe op een bestaand ggplot-object,
#' waaronder opmaak van titel, ondertitel, caption en as-tekst. Optioneel
#' kunnen uitgebreide elementen worden toegevoegd zoals legenda-positie,
#' facet-opmaak en x-as marge.
#'
#' @param p Een ggplot-object waaraan thema-elementen worden toegevoegd.
#' @param title_subtitle Logical. Indien `TRUE` (standaard), worden titel- en
#'   ondertitel-opmaak toegepast.
#' @param extended Logical. Indien `TRUE`, worden extra thema-elementen
#'   toegevoegd: legenda onderaan, verborgen legenda-titel, minimale
#'   gridlijnen en grotere facet-labels. Standaard `FALSE`.
#'
#' @return Het aangepaste ggplot-object.
#'
#' @importFrom ggplot2 theme element_text element_blank margin
#' @importFrom ggtext element_markdown element_textbox_simple
#' @export
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
