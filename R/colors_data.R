## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## colors_data.R ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
## Verspreiding buiten De HHs: Nee
##
## Doel: Kleurdefinities voor visualisaties
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#' Standaard kleurenpalet voor NFWA visualisaties
#'
#' Een named vector met standaardkleuren voor titels, tekst, achtergronden,
#' gridlijnen, en fairness-indicatoren.
#'
#' @format Een named character vector met hex-codes en kleurnamen:
#' \describe{
#'   \item{title_color}{Kleur voor hoofdtitels (zwart)}
#'   \item{positive_color}{Kleur voor positieve waarden (blauw)}
#'   \item{negative_color}{Kleur voor negatieve waarden (rood)}
#'   \item{metrics_green}{Kleur voor groene metrieken}
#'   \item{metrics_red}{Kleur voor rode metrieken}
#'   \item{color_bias_positive}{Kleur voor positieve bias (groen)}
#'   \item{color_bias_negative}{Kleur voor negatieve bias (roze)}
#'   \item{color_bias_neutral}{Kleur voor neutrale bias (oranje)}
#'   \item{color_bias_none}{Kleur voor geen bias (grijs)}
#' }
#'
#' @export
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

#' Specifieke kleurenpaletten voor sensitieve variabelen
#'
#' Een named list met kleurvectoren voor verschillende categorische variabelen
#' zoals geslacht, vooropleiding en aansluiting.
#'
#' @format Een named list met kleurvectoren:
#' \describe{
#'   \item{geslacht}{Kleuren voor geslacht (M, V)}
#'   \item{vooropleiding}{Kleuren voor vooropleiding (MBO, HAVO, VWO, etc.)}
#'   \item{aansluiting}{Kleuren voor type aansluiting (Direct, Tussenjaar, etc.)}
#'   \item{roc_plots}{Kleuren voor ROC-curve plots}
#' }
#'
#' @export
colors_list <- list()

colors_list[["geslacht"]] <- c("M" = "#1170AA",
                              "V" = "#FC7D0B")

colors_list[["vooropleiding"]] <- c(
  "MBO"                     = "#1170AA",
  "HAVO"                    = "#FC7D0B",
  "VWO"                     = "#F1CE63",
  "BD"                      = "#A3CCE9",
  "CD"                      = "#57606C",
  "HO"                      = "#9467BD",
  "Overig"                  = "#A3ACB9",
  "Onbekend"                = "#C8D0D9"
)

colors_list[["aansluiting"]] <- c(
  "Direct"                  = "#FC7D0B",
  "Tussenjaar"              = "#1170AA",
  "Switch intern"           = "#5FA2CE",
  "Switch extern"           = "#A3CCE9",
  "2e Studie"               = "#F1CE63",
  "Na CD"                   = "#57606C",
  "Overig"                  = "#A3ACB9",
  "Onbekend"                = "#C8D0D9"
)

colors_list[["roc_plots"]] <- c(
  "#fc7d0b",
  "#1170aa",
  "#c85200",
  "#a3cce9"
)
