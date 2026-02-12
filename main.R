## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## main.R - Voorbeeld script voor NFWA fairness-analyse ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
##
## Dit script demonstreert hoe je het NFWA package gebruikt voor een
## complete fairness-analyse op studiedata.
##
## BELANGRIJK: Dit script werkt alleen binnen het development project.
## Voor package gebruik, zie de vignette: vignette("nfwa-gebruiksvoorbeeld")
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Setup ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Laad het NFWA package
# Voor development: gebruik devtools::load_all()
# Na installatie: library(nfwa)
devtools::load_all()

# Laad configuratie (optioneel - kan ook handmatig ingesteld worden)
# Als config package beschikbaar is, gebruik dan config.yml
if (requireNamespace("config", quietly = TRUE) && file.exists("config.yml")) {
  config <- config::get()
} else {
  # Fallback: gebruik default waarden
  config <- list(
    params = list(
      opleidingsnaam = "B International Business Administration",
      eoi = 2010,
      opleidingsvorm = "VT"
    )
  )
  message("Let op: config package niet gevonden, gebruik default waarden")
  message("Installeer config package of pas hieronder handmatig de waarden aan")
}

# Installeer benodigde dependencies (alleen eerste keer)
if (!tinytex::is_tinytex()) {
  message("TinyTeX niet gevonden - installeren...")
  tinytex::install_tinytex()
}

# Installeer rio formats voor Parquet support (alleen eerste keer)
if (!requireNamespace("nanoparquet", quietly = TRUE)) {
  message("nanoparquet niet gevonden - installeren...")
  rio::install_formats(type = "binary")
}

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## INPUT - Configuratie ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Opleidingsinformatie
opleidingsnaam <- config$params$opleidingsnaam  # Bijv. "Informatica"
eoi <- config$params$eoi                        # Eerste jaar aan opleiding/instelling
opleidingsvorm <- config$params$opleidingsvorm  # VT, DT, of DU

# Laad je 1CHO data
# Pas de paden aan naar waar jouw bestanden staan!
df1cho <- rio::import(
  fs::path("data", "input", "EV299XX24_DEMO.parquet")
)

df1cho_vak <- rio::import(
  fs::path("data", "input", "VAKHAVW_99XX_DEMO.parquet")
)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Metadata Inlezen ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Lees de meegeleverde metadata in
# Deze zit automatisch in het package - geen eigen bestanden nodig!
metadata <- nfwa::read_metadata()

# Haal belangrijke componenten eruit
sensitive_variables <- metadata$sensitive_variables  # Bijv. geslacht, vooropleiding
mapping_newname <- metadata$mapping_newname          # Voor hernoeming variabelen
df_levels <- metadata$df_levels                      # Labels voor categorieën

message("Metadata ingelezen:")
message("  - ", length(metadata$variables), " variabelen")
message("  - ", length(sensitive_variables), " sensitieve variabelen: ",
        paste(sensitive_variables, collapse = ", "))

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Transform Data ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

message("\nData transformeren...")

# Transformeer ruwe 1CHO data naar analyse-klaar formaat
df <- transform_data(
  metadata = metadata,
  opleidingsnaam = opleidingsnaam,
  opleidingsvorm = opleidingsvorm,
  eoi = eoi,
  df1cho = df1cho,
  df1cho_vak = df1cho_vak
)

message("  - ", nrow(df), " studenten in analyse")
message("  - Retentie: ", round(mean(df$retentie) * 100, 1), "%")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Create Data Summary (Optioneel) ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Maak beschrijvende statistieken tabellen
# Uncomment onderstaande regels om deze te genereren:

# tbl_summary <- get_table_summary(df, mapping_newname)
# flextable::save_as_image(
#   x = tbl_summary,
#   path = "output/cache/descriptive_table.png"
# )
#
# tbl_summary_sensitive <- get_table_summary_fairness(
#   df, mapping_newname, sensitive_variables
# )
# flextable::save_as_image(
#   x = tbl_summary_sensitive,
#   path = "output/cache/sensitive_variables_descriptive_table.png"
# )

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## NFWA Fairness-Analyse Uitvoeren ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

message("\nFairness-analyse uitvoeren...")

# Bepaal cutoff (vaak het gemiddelde van retentie)
cutoff <- sum(df$retentie) / nrow(df)

# Voer de complete NFWA analyse uit
# Dit traint modellen, maakt plots en genereert conclusies
run_nfwa(
  df = df,
  df_levels = df_levels,
  sensitive_variables = sensitive_variables,
  colors_default = nfwa::colors_default,  # Gebruik package kleuren
  colors_list = nfwa::colors_list,        # Gebruik package kleurenpaletten
  cutoff = cutoff,
  caption = paste0(
    "Bron: 1CHO data | Analyse: ", format(Sys.Date(), "%B %Y")
  )
)

message("  - Plots opgeslagen in output/cache/")
message("  - Resultaten tabel opgeslagen")
message("  - Conclusies opgeslagen in conclusions_list.rds")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Render PDF Rapport (Optioneel) ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Genereer een PDF rapport met Quarto
# Dit gebruikt de render_report() functie uit het NFWA package
nfwa::render_report(
  opleidingsnaam = opleidingsnaam,
  opleidingsvorm = opleidingsvorm
)

message("\n✓ NFWA analyse compleet!")
message("  Bekijk de resultaten in output/")
