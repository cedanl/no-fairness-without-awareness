<h1>Fairness Awareness (NFWA) Analysis ✨</h1>

<p>🚀 Analyze the fairness of your studyprogramme</p>

<p><a href="#"><img src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&amp;logoColor=white" alt="Windows"/></a> <a href="#"><img src="https://img.shields.io/badge/macOS-000000?logo=apple&amp;logoColor=F0F0F0" alt="macOS"/></a> <a href="#"><img src="https://img.shields.io/badge/Linux-FCC624?logo=linux&amp;logoColor=black" alt="Linux"/></a> <img src="https://badgen.net/github/last-commit/cedanl/fairnessawareness" alt="GitHub Last Commit"/> <img src="https://badgen.net/github/contributors/cedanl/fairnessawareness" alt="Contributors"/> <img src="https://img.shields.io/github/license/cedanl/fairnessawareness" alt="GitHub License"/></p>


Explore admission/retention data, train predictive models, and report potential fairness issues. The workflow starts in `main.R` and orchestrates metadata loading, data cleaning, model training, fairness checks, and Quarto reporting.

## Quick Start

-   📦 Install: R (≥4.3); Quarto CLI; a LaTeX distribution for PDF output (e.g., TinyTeX or TeX Live); system build tools for compiling R packages (e.g., Xcode Command Line Tools on macOS, Rtools on Windows).
-   🔁 Restore packages: run `renv::restore()` from the project root (already called in `main.R`, but running it once interactively avoids first-run surprises).
-   📂 Provide your parquet inputs for `df1cho` (student-level) and `df1cho_vak` (course-level). Update the paths in `main.R` to where you store them. CSV is fine too—see “Data & Configuration”.
-   ▶️ Run: execute `main.R` (e.g., `source("main.R")`). Outputs land in `output/`.

## Pipeline Walkthrough (main.R)

-   🧭 Inputs: set `opleidingsnaam`, `eoi` (enrollment year), and `opleidingsvorm` at the top of `main.R`.
-   📥 Data load: reads the provided student- and course-level parquet files you point to in `main.R`.
-   📑 Metadata: `scripts/01_read_metadata.R` reads lookup tables (`metadata/`) and returns:
    -   APCG (Armoede Probleem Cumulatie Gebied) & SES (Sociaal-Economische Status) enrichment data
    -   Variable list (`variables`) and sensitive variables (`sensitive_variables`) defined in `variabelen.xlsx`
    -   Label mappings (`mapping_newname`) and ordered factor levels (`df_levels`)
    -   Decodering lookup tables for recoding education fields
-   🔧 Transform: `scripts/02_transform_data.R` applies domain transforms (`R/transform_*`), enriches with APCG/SES, selects the modeling variables, and mean-imputes numeric NAs.
-   ⚖️ Sampling: `main.R` currently down-samples to a 50/50 retained/non-retained subset for faster experimentation.
-   📊 Descriptives: `R/get_table_summary.R` builds gtsummary/flextable tables (`output/descriptive_table.png` and `output/sensitive_variables_descriptive_table.png`).
-   🛡️ Fairness run: `scripts/03_run_nfwa.R` trains models, computes fairness diagnostics per sensitive variable, saves tables (`output/result_table.png`), and serialized conclusions (`output/conclusions_list.rds`). Colors are defined in `config/colors.R`.
-   📝 Report: Quarto renders `scripts/04_render_pdf.qmd` into `scripts/kansengelijkheidanalysis_<opleiding>_<vorm>.pdf`.

## Repository Map

-   `main.R` — entrypoint orchestrating the full pipeline.
-   `scripts/` — stage scripts (metadata, transform, NFWA run, Quarto report) plus output generated PDF.
-   `R/` — reusable functions for transforms, modeling (`run_models.R`), fairness plots/tables, and styling helpers.
-   `config/colors.R` — color palettes for plots/tables.
-   `metadata/` — input dictionaries (APCG, SES, DEC, variable definitions, factor levels).
-   `output/` — generated tables, plots, RDS conclusions, and final PDF (created at run time).
-   `renv*` — package lockfile and library management.

## Data & Configuration

-   Required inputs (you provide):
    -   Parquet or CSV for EV (1CHO) — enrollment/retention base; output from project: [1cijferho](https://github.com/cedanl/1cijferho)
    -   Parquet or CSV for VAKHAVW (1CHO) — course-level detail
    -   Metadata CSV/XLSX files already in `metadata/`
-   Update `main.R` to point to your data files (replace the sample filenames). If you use CSV, load with `read.csv`/`readr::read_csv` before passing to the transform step.
-   Adjust `metadata/variabelen.xlsx` to add/remove modeling variables or mark new sensitive fields; the pipeline reads this automatically.
-   Factor orderings come from `metadata/levels.xlsx`. Update that to control display and fairness summaries.

## How the Modeling/Fairness Step Works

-   Splits the data into train/test/validation (`initial_validation_split` with stratification on `retentie`).
-   Trains two models via tidymodels: logistic regression with elastic net (`glmnet`) and random forest (`ranger`), both tuned on the validation set.
-   Chooses the best model by highest ROC AUC, then fits it on the full training data (`last_fit`).
-   Builds an explainable model object (`R/create_explain_lf.R`), then for each sensitive variable:
    -   Picks the largest subgroup as the privileged group.
    -   Computes fairness metrics and bias labels (`FRN_Bias`).
    -   Renders density and fairness plots plus a wide summary table.
-   Conclusions per sensitive variable are saved to `output/conclusions_list.rds` for reuse in the report.

## Extending or Continuing Development

-   New data vintages: drop in new parquet/CSV files and update the paths/filenames in `main.R`.
-   New sensitive variables: mark them in `metadata/variabelen.xlsx` (`Sensitive = TRUE`); `main.R` will pick them up automatically.
-   Model tweaks:
    -   Edit `R/run_models.R` to add models or change tuning grids/recipes.
    -   Adjust the `cutoff` for fairness checks in `run_nfwa()` call within `main.R`.
-   Styling:
    -   Update `config/colors.R` for palette changes.
    -   Tweak `scripts/04_render_pdf.qmd` for report layout.
-   Possible next features:
    -   🖥️ Shiny interface: load `df1cho`/`df1cho_vak` from CSV uploads, then present dropdowns for `opleidingsnaam` and `opleidingsvorm` and run the pipeline on demand.
    -   🎛️ Parameter UI: expose the fairness cutoff, model choices, and color themes as configurable inputs.
    -   💾 Caching/intermediate saves: persist transformed data to speed up iterative runs.

## Running Pieces Independently

-   Descriptives only: run up to the “Create Data Summary” block in `main.R`.
-   Fairness only: prepare `df`, `df_levels`, and `sensitive_variables`, then call `run_nfwa()` directly.
-   Reporting only: re-run `quarto::quarto_render()` if the intermediate outputs already exist.

## Reproducibility & Conventions

-   Package versions are locked via `renv.lock`; keep `renv::snapshot()` up to date after dependency changes.
-   Functions live under `R/` and are sourced by the stage scripts; prefer adding new helpers there.
-   Outputs are written to `output/`; keep generated artifacts out of version control unless intentionally checked in.
-   Prefer `dplyr` pipelines and tidymodels idioms for consistency with existing code.

## Troubleshooting

-   Missing data paths: verify the parquet locations referenced in `main.R`.
-   Quarto/TeX errors: ensure Quarto and a LaTeX distribution are installed for PDF rendering.
-   Package compile issues: run `renv::restore()` in a clean session and ensure system build tools are available for packages like `arrow` or `glmnet`.

## Reference

-   The approach and report text reference the LTA lector’s inaugural lecture: “[No Fairness without Awareness. Toegepast onderzoek naar kansengelijkheid in het hoger onderwijs. Intreerede lectoraat Learning Technology & Analytics.](<https://zenodo.org/records/14204674>)"
