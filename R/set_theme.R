## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## set_theme.R ####
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

#' Stel het basisthema in voor ggplot2-plots
#'
#' Configureert het globale ggplot2-thema met aangepaste typografie,
#' kleuren en opmaak. Stelt `theme_minimal()` in als basis en past
#' vervolgens uitgebreide aanpassingen toe voor titels, assen, legenda
#' en achtergrond.
#'
#' @param title_font Character vector. Lettertypefamilie voor de titel.
#'   Standaard `"sans"`.
#' @param type Character. Type thema (momenteel alleen `"plot"`
#'   ondersteund). Standaard `"plot"`.
#'
#' @return Onzichtbaar. Past het globale ggplot2-thema aan via
#'   [ggplot2::theme_set()] en [ggplot2::theme_update()].
#'
#' @importFrom ggplot2 theme_set theme_minimal theme_update element_text
#'   element_blank element_rect margin unit
#' @importFrom ggtext element_textbox_simple
#' @export
set_theme <- function(title_font = c("sans"),
                      type = "plot") {
  theme_set(theme_minimal())
  theme_update(
    # Title and caption
    plot.title = element_textbox_simple(
      size = 16,
      lineheight = 1,
      color = colors_default["title_color"],
      face = "bold",
      padding = margin(0, 0, 0, 0),
      margin = margin(5, 0, 5, 0),
      family = title_font
    ),
    plot.subtitle = element_textbox_simple(
      size = 12,
      lineheight = 1,
      color = colors_default["subtitle_color"],
      padding = margin(0, 0, 0, 0),
      margin = margin(5, 0, 15, 0)
    ),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_textbox_simple(
      size = 8,
      color = colors_default["caption_color"],
      padding = margin(0, 0, 0, 0),
      margin = margin(15, 0, 0, 0)
    ),
    
    # Assen
    axis.title.x = element_text(face = "bold", vjust = 5),
    axis.title.y = element_text(face = "bold", margin = margin(
      t = 0,
      r = 10,
      b = 0,
      l = 0
    )),
    axis.text.x  = element_text(size = 11),
    axis.text.y  = element_text(size = 11),
    
    # Lines
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    
    # Legend
    legend.key.size = unit(.5, "cm"),
    legend.text = element_text(size = 10),
    
    # Background white and border not visible
    plot.background = element_rect(fill = colors_default["background_color"], color = NA)
    
  )
  
}
