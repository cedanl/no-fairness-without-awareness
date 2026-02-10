## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## main.R ####
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

renv::restore()

config <- config::get()

# Install TinyTeX if not already
tinytex::install_tinytex()

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## INPUT ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

opleidingsnaam <- config$params$opleidingsnaam
eoi <- config$params$eoi
opleidingsvorm <- config$params$opleidingsvorm

## TODO: Pas aan naar waar jouw parquet bestand staat.
df1cho <- rio::import(
  fs::path("data",
    "input",
    "EV299XX24_DEMO.parquet"
  )
)


df1cho_vak <- rio::import(
  fs::path(
    "data",
    "input",
    "VAKHAVW_99XX_DEMO.parquet"
  )
)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Metadata Inlezen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/read_metadata.R")
metadata <- read_metadata()

sensitive_variables <- metadata$sensitive_variables
mapping_newname <- metadata$mapping_newname
df_levels <- metadata$df_levels


## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform Data ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/transform_data.R")
df <- transform_data(metadata,
                     opleidingsnaam,
                     opleidingsvorm,
                     eoi,
                     df1cho,
                     df1cho_vak)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Create Data Summary ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 
# source("R/get_table_summary.R")
# tbl_summary <- get_table_summary(df, mapping_newname)
# flextable::save_as_image(x = tbl_summary, path = "output/cache/descriptive_table.png")
# 
# tbl_summary_sensitive <- get_table_summary_fairness(df, mapping_newname, sensitive_variables)
# flextable::save_as_image(x = tbl_summary_sensitive, path = "output/cache/sensitive_variables_descriptive_table.png")


## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## NFWA runnen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

cutoff <- sum(df$retentie) / nrow(df)
source("R/run_nfwa.R")
run_nfwa(df, df_levels, sensitive_variables, colors_default, cutoff = cutoff)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Render ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


output_filename <- paste0(
  "kansengelijkheidanalysis_",
  gsub(" ", "_", tolower(opleidingsnaam)),
  "_",
  opleidingsvorm,
  ".pdf"
)

# Render to scripts/
quarto::quarto_render(
  input = "scripts/render_pdf.qmd",
  output_file = output_filename,
  execute_params = list(subtitle = paste0(opleidingsnaam, " ", opleidingsvorm))
)

# Move it
dir.create(paste0(getwd(), "/output/"), recursive = TRUE, showWarnings = FALSE)
file.rename(
  file.path("scripts", output_filename),
  file.path("output/", output_filename)
)
