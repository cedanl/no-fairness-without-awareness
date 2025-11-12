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

library(dplyr)

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

var <- read.table("metadata/variabelen.csv", sep = ";", header = TRUE) |>
  filter(Used) |>
  pull(Variable)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/transform_1cho_data.R")
df <- transform_1cho_data(df1cho, df1cho_vak, opleidingscode = 50952, eoi = 2019)

dfapcg <- janitor::clean_names(dfapcg)

df <- df |>
  left_join(dfapcg, by = c("postcodecijfers_student_op_1_oktober" = "cbs_apcg_pc4")) |>

  mutate(cbs_apcg_tf = as.numeric(coalesce(cbs_apcg_tf, FALSE))) |>
  
  select(all_of(var))

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
table <- analyze_fairness(df, explainer)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Save names ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#write.csv(names(df), file = "metadata/variabelen.csv", row.names = FALSE)
