## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## 1cho_trail.R ####
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

opleidingscode <- 66588
eoi <- 2019
opleidingsvorm <- "VT"

library(dplyr)
source("config/colors.R")
## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Inladen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

dfapcg <- read.table("data/APCG_2019.csv", sep = ";", header = TRUE)

dfses <- read.table(
  "data/SES_PC4_2021-2022.csv",
  sep = ";",
  header = TRUE,
  dec = ","
)

df_variables <- readxl::read_xlsx("metadata/variabelen.xlsx")

variables <- df_variables |>
  filter(Used) |>
  pull(Variable)

sensitive_variables <- df_variables |>
  filter(Sensitive) |>
  pull(Variable)

mapping_newname <- df_variables |>
  select(Variable, Newname) |>
  tidyr::drop_na()

df_levels <- read.csv("metadata/levels.csv", sep = "\t") |>
  group_by(VAR_Formal_variable) |>
  arrange(VAR_Level_order, .by_group = TRUE) |>
  ungroup()

dec_vopl <- read.csv("metadata/dec/Dec_vopl.csv", sep = "|") |>
  janitor::clean_names()

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/transform_ev_data.R")
df1cho2 <- transform_ev_data(
  df1cho,
  code = opleidingscode,
  eoi = eoi,
  vorm = opleidingsvorm,
  dec_vopl = dec_vopl
)

source("R/transform_vakhavw.R")
df1cho_vak2 <- transform_vakhavw(df1cho_vak)

source("R/transform_1cho_data.R")
dfcyfer <- transform_1cho_data(df1cho2, df1cho_vak2)

source("R/add_apcg.R")
df <- add_apcg(dfapcg, dfcyfer)

source("R/add_ses.R")
df <- add_ses(df, dfses)

df <- df |>
  select(all_of(variables)) |>
  # Imputate all numeric variables with the mean
  mutate(across(where(is.numeric), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x)))

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Table Summary ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


source("R/get_table_summary.R")
tbl_summary <- get_table_summary(df, mapping_newname)

flextable::save_as_image(x = tbl_summary, path = "output/descriptive_table.png")

tbl_summary <- get_table_summary_fairness(df, mapping_newname, sensitive_variables)

flextable::save_as_image(x = tbl_summary, path = "output/sensitive_variables_descriptive_table.png")


## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Model train ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/run_models.R")
output <- run_models(df)
last_fit <- output$last_fit
best_model <- output$best_model

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Create Explain LF ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/create_explain_lf.R")
explainer <- create_explain_lf(last_fit, best_model)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Analyze Fairness ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/analyze_fairness.R")
table <- analyze_fairness(
  df,
  explainer,
  sensitive_variables,
  df_levels,
  caption = NULL,
  colors_default = colors_default,
  colors_list = colors_list
)

flextable::save_as_image(x = table, path = "output/result_table.png")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Save names ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
