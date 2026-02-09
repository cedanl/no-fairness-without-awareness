#' Genereer LaTeX-code voor een gekleurd vierkant
#'
#' Maakt LaTeX-code aan die een klein gekleurd vierkant rendert met een
#' rand. Geschikt voor gebruik in LaTeX-documenten en Quarto/RMarkdown
#' met PDF-output. Hex-kleuren worden automatisch gedefinieerd via
#' `\\providecolor`.
#'
#' @param color Character. Vulkleur als hex-code (bijv. `"#FF0000"`) of
#'   LaTeX-kleurnaam.
#' @param bordercolor Character. Randkleur als hex-code of LaTeX-kleurnaam.
#'   Standaard `"#A9A9A9"` (donkergrijs).
#' @param size Numeriek. Grootte van het vierkant in punten. Standaard `12`.
#'
#' @return Een character string met LaTeX-code die het gekleurde vierkant
#'   rendert.
#'
#' @export
get_colored_square <- function(color,
                               bordercolor = "#A9A9A9",
                               size = 12) {
  size <- as.numeric(size)
  
  make_color_def <- function(value, prefix) {
    if (grepl("^#", value)) {
      hex <- toupper(gsub("^#", "", value))
      if (!grepl("^[0-9A-F]{6}$", hex)) {
        cli::cli_abort("'{value}' is not a valid hex color")
      }
      
      name <- paste0(prefix, hex)
      list(
        color = name,
        define = sprintf("\\providecolor{%s}{HTML}{%s}\n", name, hex)
      )
    } else {
      list(color = value, define = "")
    }
  }
  
  fill <- make_color_def(color, "sqfill")
  stroke <- make_color_def(bordercolor, "sqborder")
  defs <- paste0(fill$define, stroke$define)
  
  sprintf(
    "%s\\begingroup\\setlength{\\fboxsep}{1pt}\\fcolorbox{%s}{%s}{\\rule{0pt}{%.1fpt}\\rule{%.1fpt}{0pt}}\\endgroup",
    defs,
    stroke$color,
    fill$color,
    size,
    size
  )
  
}
