# prepare_demo_data.R
#
# Dev script to prepare demo data from raw 1CHO enriched exports.
# Run this when the underlying enriched data is updated.
#
# Creates demo data where retentie depends on student features so the
# ML model produces a meaningful AUC (~0.7+) and the fairness analysis
# detects bias on the sensitive variables (geslacht, vooropleiding, aansluiting).
#
# Input:  Full enriched EV and VAKHAVW CSV files (place in data/input/)
# Output: Trimmed demo files with ~50% retentie and strong feature signal
#
# Usage:
#   source("dev/prepare_demo_data.R")

library(dplyr)

set.seed(42)

# --- Configuration ---
input_ev      <- "data/input/EV299XX24_DEMO_enriched.csv"
input_vakhavw <- "data/input/VAKHAVW_99XX_DEMO_enriched.csv"
keep_programs <- c("B Tandheelkunde", "M Tandheelkunde")
target_retentie <- 0.50

# --- Step 1: Read and clean ---
ev  <- read.csv(input_ev, sep = ";", stringsAsFactors = FALSE) |> janitor::clean_names()
vak <- read.csv(input_vakhavw, sep = ";", stringsAsFactors = FALSE) |> janitor::clean_names()

cat("Original EV rows:", nrow(ev), "\n")
cat("Original VAKHAVW rows:", nrow(vak), "\n")

# --- Step 2: Keep only selected programs ---
ev_sub <- ev |> filter(opleidingscode_naam_opleiding %in% keep_programs)

cat("\nPrograms kept:\n")
print(table(ev_sub$opleidingscode_naam_opleiding))

# --- Step 3: Identify first-year VT students ---
eerste_jaars <- ev_sub |>
  filter(
    inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling,
    opleidingsvorm == "voltijd"
  )

cat("\nFirst-year VT students:", nrow(eerste_jaars), "\n")

# --- Step 4: Remove ALL existing year+1 rows for a clean slate ---
year2_rows <- ev_sub |>
  semi_join(
    eerste_jaars |>
      mutate(target_year = eerste_jaar_aan_deze_opleiding_instelling + 1L) |>
      select(persoonsgebonden_nummer, target_year),
    by = c("persoonsgebonden_nummer", "inschrijvingsjaar" = "target_year")
  )

ev_clean <- anti_join(ev_sub, year2_rows)
cat("Removed", nrow(year2_rows), "existing year+1 rows\n")

# --- Step 5: Compute retentie probability based on features ---

# Join grade data
vak_avg <- vak |>
  group_by(persoonsgebonden_nummer) |>
  summarise(
    gem_cijfer = max(gemiddeld_cijfer_cijferlijst, na.rm = TRUE),
    gem_se = mean(cijfer_schoolexamen, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    gem_cijfer = ifelse(is.infinite(gem_cijfer), NA_real_, gem_cijfer),
    gem_se = ifelse(is.nan(gem_se), NA_real_, gem_se)
  )

eerste_scored <- eerste_jaars |>
  left_join(vak_avg, by = "persoonsgebonden_nummer") |>
  mutate(
    # --- Vooropleiding (sensitive variable, strong signal) ---
    vooropl_cat = case_when(
      grepl("^vwo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "VWO",
      grepl("^havo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "HAVO",
      grepl("^mbo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "MBO",
      grepl("^wo|^hbo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "HO",
      TRUE ~ "Overig"
    ),
    vooropl_logit = case_when(
      vooropl_cat == "VWO"   ~  1.5,
      vooropl_cat == "HO"    ~  0.4,
      vooropl_cat == "HAVO"  ~  0.0,
      vooropl_cat == "MBO"   ~ -1.2,
      TRUE                   ~ -0.8
    ),

    # --- Aansluiting (sensitive variable, strong signal) ---
    # Simplified version of the aansluiting logic from transform_ev_data.R
    inschrijvingsjaar_int = suppressWarnings(as.integer(inschrijvingsjaar)),
    diplomajaar_int = suppressWarnings(as.integer(diplomajaar_hoogste_vooropleiding)),
    eerste_inst_int = suppressWarnings(as.integer(eerste_jaar_aan_deze_instelling)),
    is_eerstejaars = grepl("eerstejaars", indicatie_eerstejaars_continu_type_ho_binnen_ho, ignore.case = TRUE),
    is_2e_studie = grepl("echte neveninschrijving", soort_inschrijving_continu_hoger_onderwijs, ignore.case = TRUE),

    aansluiting_cat = case_when(
      is_2e_studie ~ "2e Studie",
      !is.na(diplomajaar_int) & is_eerstejaars &
        diplomajaar_int == (inschrijvingsjaar_int - 1L) ~ "Direct",
      !is.na(diplomajaar_int) & is_eerstejaars &
        diplomajaar_int < (inschrijvingsjaar_int - 1L) ~ "Tussenjaar",
      !is_eerstejaars & !is.na(eerste_inst_int) &
        eerste_inst_int == inschrijvingsjaar_int ~ "Switch extern",
      !is_eerstejaars & !is.na(eerste_inst_int) &
        eerste_inst_int < inschrijvingsjaar_int ~ "Switch intern",
      TRUE ~ "Overig"
    ),
    aansluiting_logit = case_when(
      aansluiting_cat == "Direct"        ~  1.2,
      aansluiting_cat == "2e Studie"     ~  0.5,
      aansluiting_cat == "Tussenjaar"    ~ -0.5,
      aansluiting_cat == "Switch intern" ~ -1.0,
      aansluiting_cat == "Switch extern" ~ -1.4,
      TRUE                               ~ -0.2
    ),

    # --- Geslacht (sensitive variable, moderate signal) ---
    gender_logit = ifelse(geslacht == "vrouw", 0.8, -0.8),

    # --- Grades (non-sensitive, adds realism) ---
    grade_z = ifelse(
      !is.na(gem_cijfer),
      (gem_cijfer - mean(gem_cijfer, na.rm = TRUE)) / sd(gem_cijfer, na.rm = TRUE),
      0
    ),
    grade_logit = grade_z * 0.8,

    # --- Age (non-sensitive, small effect) ---
    age = suppressWarnings(as.numeric(leeftijd_per_peildatum_1_oktober)),
    age_logit = ifelse(!is.na(age), -(age - 19) * 0.15, 0),

    # --- Combined logit ---
    # Sensitive variables carry most of the weight
    raw_logit = vooropl_logit + aansluiting_logit + gender_logit +
                grade_logit + age_logit
  )

# Scale to hit target retentie
logit <- function(p) log(p / (1 - p))
inv_logit <- function(x) 1 / (1 + exp(-x))

shift <- optimise(
  function(s) (mean(inv_logit(eerste_scored$raw_logit + s)) - target_retentie)^2,
  interval = c(-5, 5)
)$minimum

eerste_scored$prob_final <- inv_logit(eerste_scored$raw_logit + shift)

cat("\nRetentie probability distribution:\n")
print(summary(eerste_scored$prob_final))
cat("Expected retentie:", round(mean(eerste_scored$prob_final) * 100, 1), "%\n")

# Show signal per sensitive variable
cat("\nSignal per sensitive variable:\n")
cat("  Geslacht:\n")
for (g in unique(eerste_scored$geslacht)) {
  sub <- eerste_scored |> filter(geslacht == g)
  cat(sprintf("    %-10s mean_prob=%.2f  n=%d\n", g, mean(sub$prob_final), nrow(sub)))
}
cat("  Vooropleiding:\n")
for (v in c("VWO", "HAVO", "HO", "MBO", "Overig")) {
  sub <- eerste_scored |> filter(vooropl_cat == v)
  if (nrow(sub) == 0) next
  cat(sprintf("    %-10s mean_prob=%.2f  n=%d\n", v, mean(sub$prob_final), nrow(sub)))
}
cat("  Aansluiting:\n")
for (a in c("Direct", "Tussenjaar", "Switch intern", "Switch extern", "2e Studie", "Overig")) {
  sub <- eerste_scored |> filter(aansluiting_cat == a)
  if (nrow(sub) == 0) next
  cat(sprintf("    %-15s mean_prob=%.2f  n=%d\n", a, mean(sub$prob_final), nrow(sub)))
}

# --- Step 6: Sample retentie based on probability ---
eerste_scored$gets_retentie <- runif(nrow(eerste_scored)) < eerste_scored$prob_final

cat("\nActual retentie:", round(mean(eerste_scored$gets_retentie) * 100, 1), "%\n")

# Create year+1 rows
to_add <- eerste_scored |>
  filter(gets_retentie) |>
  select(all_of(names(eerste_jaars)))

new_rows <- to_add |> mutate(inschrijvingsjaar = inschrijvingsjaar + 1L)

ev_final <- bind_rows(ev_clean, new_rows) |>
  arrange(persoonsgebonden_nummer, inschrijvingsjaar)

cat("Added", nrow(new_rows), "year+1 enrollment rows\n")

# --- Step 7: Filter VAKHAVW to matching students ---
vak_final <- vak |>
  filter(persoonsgebonden_nummer %in% unique(ev_final$persoonsgebonden_nummer))

# --- Step 8: Restore original column names and write ---
orig_ev_headers  <- names(read.csv(input_ev, sep = ";", nrows = 1))
orig_vak_headers <- names(read.csv(input_vakhavw, sep = ";", nrows = 1))

names(ev_final)  <- orig_ev_headers
names(vak_final) <- orig_vak_headers

output_ev      <- paste0(tools::file_path_sans_ext(input_ev), "_prepared.", tools::file_ext(input_ev))
output_vakhavw <- paste0(tools::file_path_sans_ext(input_vakhavw), "_prepared.", tools::file_ext(input_vakhavw))

write.csv2(ev_final,  output_ev,      row.names = FALSE)
write.csv2(vak_final, output_vakhavw, row.names = FALSE)

# --- Step 9: Verify ---
cat("\n--- Verification ---\n")
cat("Final EV rows:", nrow(ev_final), "\n")
cat("Final VAKHAVW rows:", nrow(vak_final), "\n")
cat("File sizes: EV =", round(file.size(output_ev) / 1024^2, 1), "MB,",
    "VAKHAVW =", round(file.size(output_vakhavw) / 1024^2, 1), "MB\n\n")

ev_check <- ev_final |> setNames(janitor::make_clean_names(names(ev_final)))
for (naam in keep_programs) {
  for (eoi in c(2018, 2020)) {
    sub <- ev_check |>
      mutate(across(opleidingsvorm, ~ case_when(
        . == "voltijd" ~ "VT", . == "deeltijd" ~ "DT", TRUE ~ .
      ))) |>
      filter(opleidingscode_naam_opleiding == naam, opleidingsvorm == "VT",
             eerste_jaar_aan_deze_opleiding_instelling >= eoi) |>
      group_by(persoonsgebonden_nummer) |>
      mutate(retentie = any(inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling + 1)) |>
      ungroup() |>
      filter(inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling)
    if (nrow(sub) < 10) next
    cat(sprintf("  %-30s eoi>=%d  n=%-5d ret=%.0f%%\n",
                naam, eoi, nrow(sub), mean(sub$retentie) * 100))
  }
}
