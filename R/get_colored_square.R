library(glue)


get_colored_square <- function(color,
                               bordercolor = "#A9A9A9",
                               size = 12) {
  size <- as.numeric(size)
  
  make_color_def <- function(value, prefix) {
    if (grepl("^#", value)) {
      hex <- toupper(gsub("^#", "", value))
      if (!grepl("^[0-9A-F]{6}$", hex)) {
        cli_abort("'{value}' is not a valid hex color")
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
