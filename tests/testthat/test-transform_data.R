test_that("transform_data retourneert geldig data frame met demo data", {
  skip_if_not(
    file.exists("data/input/EV299XX24_DEMO.csv"),
    "Demo data niet beschikbaar"
  )

  data_ev      <- read.csv("data/input/EV299XX24_DEMO.csv", sep = ";")
  data_vakhavw <- read.csv("data/input/VAKHAVW_99XX_DEMO.csv", sep = ";")
  metadata     <- read_metadata()

  result <- transform_data(
    metadata       = metadata,
    opleidingsnaam = "B Bedrijfskunde",
    opleidingsvorm = "VT",
    eoi            = 2010,
    data_ev        = data_ev,
    data_vakhavw   = data_vakhavw
  )

  expect_true(is.data.frame(result))
  expect_gt(nrow(result), 0)
  expect_true("retentie" %in% names(result))
  expect_false(anyNA(result$retentie))
})

test_that("transform_data bevat alle verwachte modelvariabelen", {
  skip_if_not(
    file.exists("data/input/EV299XX24_DEMO.csv"),
    "Demo data niet beschikbaar"
  )

  data_ev      <- read.csv("data/input/EV299XX24_DEMO.csv", sep = ";")
  data_vakhavw <- read.csv("data/input/VAKHAVW_99XX_DEMO.csv", sep = ";")
  metadata     <- read_metadata()

  result <- transform_data(
    metadata       = metadata,
    opleidingsnaam = "B Bedrijfskunde",
    opleidingsvorm = "VT",
    eoi            = 2010,
    data_ev        = data_ev,
    data_vakhavw   = data_vakhavw
  )

  verwachte_vars <- c(
    "persoonsgebonden_nummer", "inschrijvingsjaar", "geslacht",
    "leeftijd_per_peildatum_1_oktober", "retentie",
    "gemiddeld_cijfer_cijferlijst", "entl", "nat", "netl",
    "cbs_apcg_tf", "ses_deelscore_arbeid", "ses_deelscore_welvaart",
    "dubbele_studie", "ses_totaalscore", "wis",
    "entl_missing", "wis_missing", "netl_missing", "nat_missing",
    "cijfer_schoolexamen", "vooropleiding", "aansluiting"
  )

  expect_true(all(verwachte_vars %in% names(result)))
})

test_that("transform_data bevat geen ontbrekende waarden in numerieke variabelen", {
  skip_if_not(
    file.exists("data/input/EV299XX24_DEMO.csv"),
    "Demo data niet beschikbaar"
  )

  data_ev      <- read.csv("data/input/EV299XX24_DEMO.csv", sep = ";")
  data_vakhavw <- read.csv("data/input/VAKHAVW_99XX_DEMO.csv", sep = ";")
  metadata     <- read_metadata()

  result <- transform_data(
    metadata       = metadata,
    opleidingsnaam = "B Bedrijfskunde",
    opleidingsvorm = "VT",
    eoi            = 2010,
    data_ev        = data_ev,
    data_vakhavw   = data_vakhavw
  )

  numerieke_vars <- names(result)[sapply(result, is.numeric)]
  expect_false(anyNA(result[, numerieke_vars]))
})
