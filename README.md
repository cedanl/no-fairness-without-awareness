# Fairness Awareness (NFWA) Analysis

End-to-end R pipeline for the HHs Lectoraat Learning Technology & Analytics to explore admission/retention data, train predictive models, and report potential fairness issues. The workflow starts in `main.R` and orchestrates metadata loading, data cleaning, model training, fairness checks, and Quarto reporting.

## Quick Start
- Install: R (≥4.3), Quarto (for PDF rendering), and a TeX engine if you want PDF output. Open the project (`ceda-fairnessawareness.Rproj`) in RStudio or use the terminal.
- Restore packages: run `renv::restore()` from the project root (already called in `main.R`, but running it once interactively avoids first-run surprises).
- Provide your parquet inputs for `df1cho` (student-level) and `df1cho_vak` (course-level). Update the paths in `main.R` to where you store them.
- Run: execute `main.R` (e.g., `source("main.R")`). Outputs land in `output/`.

## Pipeline Walkthrough (main.R)
- Inputs: set `opleidingsnaam`, `eoi` (enrollment year), and `opleidingsvorm` at the top of `main.R`.
- Data load: reads the provided student- and course-level parquet files you point to in `main.R`.
- Metadata: `scripts/01_read_metadata.R` reads lookup tables (`metadata/`) and returns:
  - APCG & SES enrichment data
  - Variable list (`variables`) and sensitive variables (`sensitive_variables`) defined in `variabelen.xlsx`
  - Label mappings (`mapping_newname`) and ordered factor levels (`df_levels`)
  - DEC lookup tables for recoding education fields
- Transform: `scripts/02_transform_data.R` applies domain transforms (`R/transform_*`), enriches with APCG/SES, selects the modeling variables, and mean-imputes numeric NAs.
- Sampling: `main.R` currently down-samples to a 50/50 retained/non-retained subset for faster experimentation.
- Descriptives: `R/get_table_summary.R` builds gtsummary/flextable tables (`output/descriptive_table.png` and `output/sensitive_variables_descriptive_table.png`).
- Fairness run: `scripts/03_run_nfwa.R` trains models, computes fairness diagnostics per sensitive variable, saves tables (`output/result_table.png`), and serialized conclusions (`output/conclusions_list.rds`). Colors are defined in `config/colors.R`.
- Report: Quarto renders `scripts/04_render_pdf.qmd` into `output/kansengelijkheidanalysis_<opleiding>_<vorm>.pdf`.

## Repository Map
- `main.R` — entrypoint orchestrating the full pipeline.
- `scripts/` — stage scripts (metadata, transform, NFWA run, Quarto report) plus a sample generated PDF.
- `R/` — reusable functions for transforms, modeling (`run_models.R`), fairness plots/tables, and styling helpers.
- `config/colors.R` — color palettes for plots/tables.
- `metadata/` — input dictionaries (APCG, SES, DEC, variable definitions, factor levels).
- `output/` — generated tables, plots, RDS conclusions, and final PDF (created at run time).
- `renv*` — package lockfile and library management.

## Data & Configuration
- Required inputs (you provide):
  - Parquet for `df1cho` — enrollment/retention base
  - Parquet for `df1cho_vak` — course-level detail
  - Metadata CSV/XLSX files already in `metadata/`
- Update `main.R` to point to your parquet files (replace the sample filenames).
- Adjust `metadata/variabelen.xlsx` to add/remove modeling variables or mark new sensitive fields; the pipeline reads this automatically.
- Factor orderings come from `metadata/levels.xlsx`. Update that to control display and fairness summaries.

## How the Modeling/Fairness Step Works
- Splits the data into train/test/validation (`initial_validation_split` with stratification on `retentie`).
- Trains two models via tidymodels: logistic regression with elastic net (`glmnet`) and random forest (`ranger`), both tuned on the validation set.
- Chooses the best model by highest ROC AUC, then fits it on the full training data (`last_fit`).
- Builds an explainable model object (`R/create_explain_lf.R`), then for each sensitive variable:
  - Picks the largest subgroup as the privileged group.
  - Computes fairness metrics and bias labels (`FRN_Bias`).
  - Renders density and fairness plots plus a wide summary table.
- Conclusions per sensitive variable are saved to `output/conclusions_list.rds` for reuse in the report.

## Extending or Continuing Development
- New data vintages: drop in new parquet files and update the paths/filenames in `main.R`.
- New sensitive variables: mark them in `metadata/variabelen.xlsx` (`Sensitive = TRUE`); `main.R` will pick them up automatically.
- Model tweaks:
  - Edit `R/run_models.R` to add models or change tuning grids/recipes.
  - Adjust the `cutoff` for fairness checks in `run_nfwa()` call within `main.R`.
- Styling:
  - Update `config/colors.R` for palette changes.
  - Tweak `scripts/04_render_pdf.qmd` for report layout.
- Performance: remove the temporary down-sampling block in `main.R` (the `df_1`/`df_0` sampling) when running on full data.

## Running Pieces Independently
- Descriptives only: run up to the “Create Data Summary” block in `main.R`.
- Fairness only: prepare `df`, `df_levels`, and `sensitive_variables`, then call `run_nfwa()` directly.
- Reporting only: re-run `quarto::quarto_render()` if the intermediate outputs already exist.

## Reproducibility & Conventions
- Package versions are locked via `renv.lock`; keep `renv::snapshot()` up to date after dependency changes.
- Functions live under `R/` and are sourced by the stage scripts; prefer adding new helpers there.
- Outputs are written to `output/`; keep generated artifacts out of version control unless intentionally checked in.
- Prefer `dplyr` pipelines and tidymodels idioms for consistency with existing code.

## Troubleshooting
- Missing data paths: verify the parquet locations referenced in `main.R`.
- Quarto/TeX errors: ensure Quarto and a LaTeX distribution are installed for PDF rendering.
- Package compile issues: run `renv::restore()` in a clean session and ensure system build tools are available for packages like `arrow` or `glmnet`.
