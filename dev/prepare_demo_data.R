# prepare_demo_data.R
#
# Dev script to prepare demo data from raw 1CHO enriched exports.
# Run this when the underlying enriched data is updated.
#
# Creates demo data where retentie depends on student features (grades,
# vooropleiding, gender, age) so the ML model finds real signal and
# produces a meaningful AUC for fairness analysis.
#
# Input:  Full enriched EV and VAKHAVW CSV files (place in data/input/)
# Output: Trimmed demo files with realistic retentie (~50%) and feature-based signal
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

# Students who already have a year+1 enrollment
has_year2_ids <- ev_sub |>
  semi_join(
    eerste_jaars |>
      mutate(target_year = eerste_jaar_aan_deze_opleiding_instelling + 1L) |>
      select(persoonsgebonden_nummer, target_year),
    by = c("persoonsgebonden_nummer", "inschrijvingsjaar" = "target_year")
  ) |>
  distinct(persoonsgebonden_nummer) |>
  pull()

cat("\nFirst-year VT students:", nrow(eerste_jaars), "\n")
cat("Already have retentie:", length(has_year2_ids), "\n")

# --- Step 4: Remove ALL existing year+1 rows so we control retentie fully ---
# This gives us a clean slate: no student has retentie yet.
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
# Join grade data to first-year students
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
    # Classify vooropleiding
    vooropl_cat = case_when(
      grepl("^vwo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "VWO",
      grepl("^havo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "HAVO",
      grepl("^mbo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "MBO",
      grepl("^wo|^hbo", hoogste_vooropleiding_omschrijving_vooropleiding, ignore.case = TRUE) ~ "HO",
      TRUE ~ "Overig"
    ),

    # Normalize features to 0-1 range for probability calculation
    # Grades: higher = more likely to stay (strong signal)
    grade_score = ifelse(
      !is.na(gem_cijfer),
      (gem_cijfer - 55) / (85 - 55),  # range roughly 55-85
      0.5  # neutral for missing
    ),
    grade_score = pmin(pmax(grade_score, 0), 1),

    # Vooropleiding effect: VWO > HAVO > HO > MBO > Overig
    vooropl_score = case_when(
      vooropl_cat == "VWO"   ~ 0.65,
      vooropl_cat == "HO"    ~ 0.55,
      vooropl_cat == "HAVO"  ~ 0.50,
      vooropl_cat == "MBO"   ~ 0.35,
      TRUE                   ~ 0.40
    ),

    # Age effect: younger slightly more likely to stay
    age = suppressWarnings(as.numeric(leeftijd_per_peildatum_1_oktober)),
    age_score = ifelse(!is.na(age), pmax(0.3, 1 - (age - 17) * 0.04), 0.5),

    # Gender: slight difference (adds signal for fairness analysis to detect)
    gender_score = ifelse(geslacht == "vrouw", 0.55, 0.45),

    # Combine into retentie probability
    # Grades are the strongest predictor (~40%), then vooropleiding (~25%),
    # gender (~20%), age (~15%)
    prob_retentie = 0.40 * grade_score +
                    0.25 * vooropl_score +
                    0.20 * gender_score +
                    0.15 * age_score
  )

# Scale probabilities to hit target retentie rate
# Use a logit transform, shift intercept, then back to probability
logit <- function(p) log(p / (1 - p))
inv_logit <- function(x) 1 / (1 + exp(-x))

raw_logits <- logit(pmin(pmax(eerste_scored$prob_retentie, 0.01), 0.99))
# Find intercept shift that produces target_retentie on average
shift <- optimise(
  function(s) (mean(inv_logit(raw_logits + s)) - target_retentie)^2,
  interval = c(-5, 5)
)$minimum

eerste_scored$prob_final <- inv_logit(raw_logits + shift)

cat("\nRetentie probability distribution:\n")
print(summary(eerste_scored$prob_final))
cat("Expected retentie:", round(mean(eerste_scored$prob_final) * 100, 1), "%\n")

# --- Step 6: Sample retentie based on probability ---
eerste_scored$gets_retentie <- runif(nrow(eerste_scored)) < eerste_scored$prob_final

cat("Actual retentie:", round(mean(eerste_scored$gets_retentie) * 100, 1), "%\n")

# Create year+1 rows for students who get retentie
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

write.csv2(ev_final, input_ev, row.names = FALSE)
write.csv2(vak_final, input_vakhavw, row.names = FALSE)

# --- Step 9: Verify ---
cat("\n--- Verification ---\n")
cat("Final EV rows:", nrow(ev_final), "\n")
cat("Final VAKHAVW rows:", nrow(vak_final), "\n")
cat("File sizes: EV =", round(file.size(input_ev) / 1024^2, 1), "MB,",
    "VAKHAVW =", round(file.size(input_vakhavw) / 1024^2, 1), "MB\n\n")

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
