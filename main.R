## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## main.R - Voorbeeld script voor NFWA fairness-analyse ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## R code voor Lectoraat Learning Technology & Analytics De Haagse Hogeschool
## Copyright 2025 De HHs
## Web Page: http://www.hhs.nl
## Contact: Theo Bakker (t.c.bakker@hhs.nl)
##
## Dit script demonstreert twee manieren om het NFWA package te gebruiken:
## 1. SNELSTART: Gebruik analyze_fairness() voor complete analyse in één functie
## 2. STAP-VOOR-STAP: Handmatige controle over elke stap
##
## BELANGRIJK: Dit script werkt alleen binnen het development project.
## Voor package gebruik, zie de vignette: vignette("nfwa-gebruiksvoorbeeld")
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Setup ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Laad het NFWA package
devtools::load_all()

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## INPUT - Configuratie ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Opleidingsinformatie
opleidingsnaam = "B International Business Administration"
eoi = 2010
opleidingsvorm = "VT"

# Laad je 1CHO data
# Pas de paden aan naar waar jouw bestanden staan!
data_ev <- read.csv(
  fs::path("data", "input", "EV299XX24_DEMO.csv"), sep = ";"
)

data_vakhavw <- read.csv(
  fs::path("data", "input", "VAKHAVW_99XX_DEMO.csv"), sep = ";"
)

# ## . ####
# ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ## OPTIE 1: SNELSTART - Complete analyse met één functie ####
# ## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 
# # Uncomment deze sectie om de snelle 1-functie aanpak te gebruiken:
# 
# result <- nfwa::analyze_fairness(
#   data_ev = data_ev,
#   data_vakhavw = data_vakhavw,
#   opleidingsnaam = opleidingsnaam,
#   eoi = eoi,
#   opleidingsvorm = opleidingsvorm,
#   generate_pdf = TRUE,
#   cleanup_temp = TRUE
# )

# # Klaar! Het PDF rapport staat in je working directory.
# # Bekijk het getransformeerde dataframe:
# # head(result$df)

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## OPTIE 2: STAP-VOOR-STAP - Handmatige controle ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Stap 1: Metadata Inlezen ####
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
## Stap 2: Transform Data ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

message("\nData transformeren...")

# Transformeer ruwe 1CHO data naar analyse-klaar formaat
df <- nfwa::transform_data(
  metadata = metadata,
  opleidingsnaam = opleidingsnaam,
  opleidingsvorm = opleidingsvorm,
  eoi = eoi,
  data_ev = data_ev,
  data_vakhavw = data_vakhavw
)

message("  - ", nrow(df), " studenten in analyse")
message("  - Retentie: ", round(mean(df$retentie) * 100, 1), "%")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## (Optioneel) Create Data Summary ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Maak beschrijvende statistieken tabellen
# Uncomment onderstaande regels om deze te genereren:

# tbl_summary <- get_table_summary(df, mapping_newname)
# flextable::save_as_image(
#   x = tbl_summary,
#   path = "temp/descriptive_table.png"
# )
#
# tbl_summary_sensitive <- get_table_summary_fairness(
#   df, mapping_newname, sensitive_variables
# )
# flextable::save_as_image(
#   x = tbl_summary_sensitive,
#   path = "temp/sensitive_variables_descriptive_table.png"
# )

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Stap 3: NFWA Fairness-Analyse Uitvoeren ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

message("\nFairness-analyse uitvoeren...")

# Bepaal cutoff (vaak het gemiddelde van retentie)
cutoff <- sum(df$retentie) / nrow(df)

# Voer de complete NFWA analyse uit
# Dit traint modellen, maakt plots en genereert conclusies
nfwa::run_nfwa(
  df = df,
  df_levels = df_levels,
  sensitive_variables = sensitive_variables,
  cutoff = cutoff,
  eoi = eoi,
  caption = paste0(
    "Bron: 1CHO data | Analyse: ", format(Sys.Date(), "%B %Y")
  )
)

message("  - Plots opgeslagen in temp/")
message("  - Resultaten tabel opgeslagen")
message("  - Conclusies opgeslagen in conclusions_list.rds")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Stap 4: Render PDF Rapport (Optioneel) ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Genereer een PDF rapport met Quarto
# Dit gebruikt de render_report() functie uit het NFWA package
nfwa::render_report(
  opleidingsnaam = opleidingsnaam,
  opleidingsvorm = opleidingsvorm,
  cleanup_temp = FALSE  # Set to TRUE om tijdelijke bestanden te verwijderen
)


message("\n NFWA analyse compleet!")

## . ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Cleanup Tijdelijke Bestanden (Optioneel) ####
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Als je de tijdelijke bestanden wilt verwijderen na het genereren van het rapport:
# nfwa::cleanup_temp()
