# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# colors.R ####
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# R code of the Learning Technology & Analytics Research Group of THUAS
# Copyright 2025 THUAS
# Web Page: http://www.thuas.com
# Contact: Theo Bakker (t.c.bakker@hhs.nl)
# Distribution outside THUAS: Yes
#
# Purpose: Inclusion of the color settings
#
# Dependencies: None
#
# Datasets: DNA
#
# Remarks:
# 1) None.
# 2) ___
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# . ####
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 1. COLOR LISTS ####
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 1.1 Standard colors ####

colors_default <- c(
  
  # Colors of title, subject, subtitle, caption, background
  title_color                = "black",
  subject_color              = "#808080",
  subtitle_color             = "black",
  subtitle_prefix_color      = "#808080",
  subtitle_warning_color     = "#C8133B",
  caption_color              = "darkgray",
  background_color           = "white",
  
  # Color of text
  text_color                 = "black",
  text_inside_color          = "white",
  
  # Intercept (0) and gridlines
  baseline_color             = "black",
  gridline_color             = "#CBCBCB",
  deadline_color             = "black",
  baseline_color_ses         = "darkgray",
  breakdown_intercept_color  = "black",
  breakdown_segment_color    = "darkgray",
  
  # Fill color
  fill_color                 = "lightgray",
  
  # Line color
  average_line_color         = "#CBCBCB",
  
  # Text color
  average_text_color         = "darkgray",
  
  # Color of annotations
  annotation_text_color      = "black",
  arrow_color                = "darkgray",
  
  # Color of jitter
  jitter_color               = "darkgray",
  
  # Error band color
  se_color                   = "#CBCBCB",
  
  # Band color
  band_color                 = "grey95",
  
  # Positive and negative
  positive_color             = "#466F9D",
  negative_color             = "#C8133B",
  
  # Metrics
  metrics_green              = "#287233",
  metrics_red                = "#C8133B",
  metrics_yellow             = "#FFD966",
  metrics_blue               = "#5FA2CE",
  
  # Bias colors
  color_bias_positive        = "#9DBF9E",
  color_bias_negative        = "#A84268",
  color_bias_neutral         = "#FCB97D",
  color_bias_none            = "#E5E5E5"
)

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 1.2 Specific colors ####

color_list <- list()

color_list[["geslacht"]] <- c("M" = "#1170AA",
                              "V" = "#FC7D0B")

color_list[["Vooropleiding"]] <- c(
  "MBO"                     = "#1170AA",
  "HAVO"                    = "#FC7D0B",
  "VWO"                     = "#F1CE63",
  "BD"                      = "#A3CCE9",
  "CD"                      = "#57606C",
  "HO"                      = "#9467BD",
  "Overig"                  = "#A3ACB9",
  "Onbekend"                = "#C8D0D9"
)

color_list[["Aansluiting"]] <- c(
  "Direct"                  = "#FC7D0B",
  "Tussenjaar"              = "#1170AA",
  "Switch intern"           = "#5FA2CE",
  "Switch extern"           = "#A3CCE9",
  "2e Studie"               = "#F1CE63",
  "Na CD"                   = "#57606C",
  "Overig"                  = "#A3ACB9",
  "Onbekend"                = "#C8D0D9"
)

color_list[["roc_plots"]] <- c(
  "#fc7d0b",
  "#1170aa",
  "#c85200",
  "#a3cce9"
)

# color_list[["institution"]] <- c(
#   "institution-color-one"   = brand_data$color$palette$`institution-color-one`,  # Green
#   "institution-color-two"   = brand_data$color$palette$`institution-color-two`,  # Blue
#   "institution-color-three" = brand_data$color$palette$`institution-color-three` # Orange
# )
