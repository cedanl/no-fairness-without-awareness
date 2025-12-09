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

set.seed(10)
renv::restore()

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## INPUT ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

opleidingsnaam <- "B Economie en Bedrijfseconomie"
eoi <- 2010
opleidingsvorm <- "VT"

df1cho <- arrow::read_parquet(
  fs::path(
    Sys.getenv("LTA_ROOT"),
    "00 LTA Data",
    "1CHO",
    "synthetische data",
    "EV299XX24.parquet"
  )
)


df1cho_vak <- arrow::read_parquet(
  fs::path(
    Sys.getenv("LTA_ROOT"),
    "00 LTA Data",
    "1CHO",
    "synthetische data",
    "VAKHAVW_99XX.parquet"
  )
)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Metadata Inlezen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("scripts/01_read_metadata.R")
metadata <- read_metadata()



## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform Data ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("scripts/02_transform_data.R")
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

sensitive_variables <- metadata$sensitive_variables
mapping_newname <- metadata$mapping_newname
df_levels <- metadata$df_levels

source("R/get_table_summary.R")
tbl_summary <- get_table_summary(df, mapping_newname)
flextable::save_as_image(x = tbl_summary, path = "output/descriptive_table.png")

tbl_summary_sensitive <- get_table_summary_fairness(df, mapping_newname, sensitive_variables)
flextable::save_as_image(x = tbl_summary_sensitive, path = "output/sensitive_variables_descriptive_table.png")


## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## NFWA runnen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("scripts/03_run_nfwa.R")
run_nfwa(df, df_levels, sensitive_variables, colors_default, cutoff = 0.2)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Render ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


quarto::quarto_render(
  input = "scripts/04_render_pdf.qmd",
  output_file = paste0(
    "kansengelijkheidanalysis_",
    gsub(" ", "_", tolower(opleidingsnaam)),
    "_",
    opleidingsvorm,
    ".pdf"
  ),
  execute_params = list(
    title = paste0(
      "De uitkomsten van de kansengelijkheidanalysis voor \t\t",
      opleidingsnaam,
      " ",
      opleidingsvorm
    )
  )
)
