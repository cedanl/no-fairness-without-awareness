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

opleidingsnaam <- "B Economie en Bedrijfseconomie"
eoi <- 2010
opleidingsvorm <- "VT"
cutoff <- 0.2

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
  dplyr::filter(Used) |>
  dplyr::pull(Variable)

sensitive_variables <- df_variables |>
  dplyr::filter(Sensitive) |>
  dplyr::pull(Variable)

mapping_newname <- df_variables |>
  dplyr::select(Variable, Newname) |>
  tidyr::drop_na()

df_levels <- readxl::read_xlsx("metadata/levels.xlsx") |>
  dplyr::group_by(VAR_Formal_variable) |>
  dplyr::arrange(VAR_Level_order, .by_group = TRUE) |>
  dplyr::ungroup()

dec_vopl <- read.csv("metadata/dec/Dec_vopl.csv", sep = "|") |>
  janitor::clean_names()

dec_isat <- read.csv("metadata/dec/Dec_isat.csv", sep = "|") |>
  janitor::clean_names()

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

source("R/transform_ev_data.R")
df1cho2 <- transform_ev_data(
  df1cho,
  naam = opleidingsnaam,
  eoi = eoi,
  vorm = opleidingsvorm,
  dec_vopl = dec_vopl,
  dec_isat = dec_isat
)

source("R/transform_vakhavw.R")
df1cho_vak2 <- transform_vakhavw(df1cho_vak)

source("R/transform_1cho_data.R")
dfcyfer <- transform_1cho_data(df1cho2, df1cho_vak2)

## Add APCG and SES data
source("R/add_apcg.R")
source("R/add_ses.R")
df <- dfcyfer |>

  add_apcg(dfapcg) |>


  add_ses(dfses) |>

  ## Select variables used in the model
  dplyr::select(dplyr::all_of(variables)) |>

  # Imputate all numeric variables with the mean
  dplyr::mutate(dplyr::across(where(is.numeric), ~ ifelse(is.na(.x), mean(.x, na.rm = TRUE), .x)))

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

## Make retentie numeric
df <- df |>
  dplyr::mutate(dplyr::across(retentie, ~ dplyr::if_else(. == 0, "0", "1")))

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

df_fairness_list <- list()

# Make a fairness analysis
for (i in 1:length(sensitive_variables)) {
  var <- sensitive_variables[i]
  
  # Determine the most common subgroup = Privileged
  source("R/get_largest_group.R")
  privileged <- get_largest_group(df, var)
  
  # Create a fairness object
  source("R/get_obj_fairness.R")
  fairness_object <- get_obj_fairness(df, explainer, var, privileged, cutoff = cfg$cutoff)
  
  ## . ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ## Create Fairness plots ####
  ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  
  source("R/create_density_plot.R")
  density_plot <- create_density_plot(
    fairness_object,
    group = var,
    caption = caption,
    colors_default = colors_default,
    colors_list = colors_list
  )
  
  n_categories <- length(unique(df[[var]])) - 1
  
  ggplot2::ggsave(
    filename = glue::glue("output/fairness_density_{var}.png"),
    height = (250 + (50 * n_categories)) / 72,
    width = 640 / 72,
    bg = colors_default[["background_color"]],
    device = ragg::agg_png,
    res = 300,
    create.dir = TRUE
  )
  
  source("R/create_fairness_plot.R")
  # Create a plot of the fairness analysis
  fairness_plot <- suppressWarnings(
    create_fairness_plot(
      fairness_object,
      group = var,
      privileged = privileged,
      colors_default = colors_default
    ) +
      ggplot2::theme(panel.border = ggplot2::element_rect(
        colour = "darkgrey",
        fill = NA,
        size = 0.4
      ))
  )

  ggplot2::ggsave(
    filename = glue::glue("output/fairness_plot_{var}.png"),
    height = (250 + (50 * n_categories)) / 72,
    width = 640 / 72,
    bg = colors_default[["background_color"]],
    device = ragg::agg_png,
    res = 300,
    create.dir = TRUE
  )
  
  source("R/get_df_fairness_check_data.R")
  df_fairness_check_data <- get_df_fairness_check_data(df, fairness_object[["fairness_check_data"]], var)
  
  df_fairness_list[[i]] <- df_fairness_check_data |>
    dplyr::mutate(
      FRN_Bias = dplyr::case_when(
        FRN_Score < 0.8 ~ "Negatieve Bias",
        FRN_Score > 1.25 ~ "Positieve Bias",
        .default = "Geen Bias"
      )
    )
}

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Create Flextable  ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# Create a table from the fairness analysis
source("R/get_df_fairness_wide.R")
df_fairness_wide  <- get_df_fairness_wide(df_fairness_list, df, df_levels, sensitive_variables)

# Create a flextable
source("R/get_ft_fairness.R")
ft_fairness <- get_ft_fairness(flextable::flextable(df_fairness_wide |>
                                           dplyr::select(-c(Groep_label, Text))), colors_default = colors_default)


flextable::save_as_image(x = ft_fairness, path = "output/result_table.png")
