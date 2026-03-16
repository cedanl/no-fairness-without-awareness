test_that("run_models retourneert list met last_fit en best_model", {
  skip_if_not(
    file.exists("data/input/EV299XX24_DEMO.csv"),
    "Demo data niet beschikbaar"
  )
  skip_if(
    Sys.getenv("NFWA_RUN_SLOW_TESTS") != "true",
    "Sla langzame modeltraining over (zet NFWA_RUN_SLOW_TESTS=true om te activeren)"
  )

  data_ev      <- read.csv("data/input/EV299XX24_DEMO.csv", sep = ";")
  data_vakhavw <- read.csv("data/input/VAKHAVW_99XX_DEMO.csv", sep = ";")
  metadata     <- read_metadata()

  df <- transform_data(
    metadata       = metadata,
    opleidingsnaam = "B Bedrijfskunde",
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
