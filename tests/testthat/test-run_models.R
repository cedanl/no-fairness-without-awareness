ev_path      <- testthat::test_path("../../data/input/EV299XX24_DEMO_enriched.csv")
vakhavw_path <- testthat::test_path("../../data/input/VAKHAVW_99XX_DEMO_enriched.csv")

test_that("run_models retourneert list met last_fit en best_model", {
  skip_if_not(file.exists(ev_path), "Demo data niet beschikbaar")
  skip_if(
    Sys.getenv("NFWA_RUN_SLOW_TESTS") != "true",
    "Sla langzame modeltraining over (zet NFWA_RUN_SLOW_TESTS=true om te activeren)"
  )

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")
  metadata     <- read_metadata()

  df <- transform_data(
    metadata       = metadata,
    opleidingsnaam = "B Tandheelkunde",
    opleidingsvorm = "VT",
    eoi            = 2010,
    data_ev        = data_ev,
    data_vakhavw   = data_vakhavw
  )

  result <- nfwa:::run_models(df)

  expect_type(result, "list")
  expect_named(result, c("last_fit", "best_model"))
  expect_true(result$best_model %in% c("Logistic Regression", "Random Forest"))
})
