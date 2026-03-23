# prepare_demo_data.R
#
# Dev script to prepare demo data from raw 1CHO enriched exports.
# Run this when the underlying enriched data is updated.
#
# Input:  Full enriched EV and VAKHAVW CSV files (place in data/input/)
# Output: Trimmed demo files with realistic retentie (~50%)
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

# --- Step 3: Identify first-year VT students without retentie ---
eerste_jaars <- ev_sub |>
  filter(
    inschrijvingsjaar == eerste_jaar_aan_deze_opleiding_instelling,
    opleidingsvorm == "voltijd"
  )

# Students who already have a year+1 enrollment
has_year2 <- ev_sub |>
  semi_join(
    eerste_jaars |>
      mutate(target_year = eerste_jaar_aan_deze_opleiding_instelling + 1L) |>
      select(persoonsgebonden_nummer, target_year),
    by = c("persoonsgebonden_nummer", "inschrijvingsjaar" = "target_year")
  ) |>
  distinct(persoonsgebonden_nummer) |>
  pull()

no_year2 <- eerste_jaars |> filter(!persoonsgebonden_nummer %in% has_year2)

current_retentie <- length(has_year2) / nrow(eerste_jaars)
cat("\nFirst-year VT students:", nrow(eerste_jaars), "\n")
cat("Current retentie:", round(current_retentie * 100, 1), "%\n")

# --- Step 4: Add year+1 rows to reach target retentie ---
needed <- round(nrow(eerste_jaars) * target_retentie) - length(has_year2)

if (needed > 0) {
  to_add <- no_year2 |> slice_sample(n = min(needed, nrow(no_year2)))
  new_rows <- to_add |> mutate(inschrijvingsjaar = inschrijvingsjaar + 1L)
  ev_final <- bind_rows(ev_sub, new_rows) |>
    arrange(persoonsgebonden_nummer, inschrijvingsjaar)
  cat("Added", nrow(new_rows), "year+1 enrollment rows\n")
} else {
  ev_final <- ev_sub
  cat("Retentie already at or above target, no rows added\n")
}

# --- Step 5: Filter VAKHAVW to matching students ---
vak_final <- vak |>
  filter(persoonsgebonden_nummer %in% unique(ev_final$persoonsgebonden_nummer))

# --- Step 6: Restore original column names and write ---
orig_ev_headers  <- names(read.csv(input_ev, sep = ";", nrows = 1))
orig_vak_headers <- names(read.csv(input_vakhavw, sep = ";", nrows = 1))

names(ev_final)  <- orig_ev_headers
names(vak_final) <- orig_vak_headers

write.csv2(ev_final, input_ev, row.names = FALSE)
write.csv2(vak_final, input_vakhavw, row.names = FALSE)

# --- Step 7: Verify ---
cat("\n--- Verification ---\n")
cat("Final EV rows:", nrow(ev_final), "\n")
cat("Final VAKHAVW rows:", nrow(vak_final), "\n")
cat("File sizes: EV =", round(file.size(input_ev) / 1024^2, 1), "MB,",
    "VAKHAVW =", round(file.size(input_vakhavw) / 1024^2, 1), "MB\n")

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
