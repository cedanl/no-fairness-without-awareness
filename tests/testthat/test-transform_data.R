ev_path      <- testthat::test_path("../../data/input/EV299XX24_DEMO_enriched.csv")
vakhavw_path <- testthat::test_path("../../data/input/VAKHAVW_99XX_DEMO_enriched.csv")

transform_result <- function() {
  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")
  metadata     <- read_metadata()

  suppressWarnings(
    transform_data(
      metadata       = metadata,
      opleidingsnaam = "B Tandheelkunde",
      opleidingsvorm = "VT",
      eoi            = 2010,
      data_ev        = data_ev,
      data_vakhavw   = data_vakhavw
    )
  )
}

test_that("transform_data retourneert geldig data frame met enriched demo data", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  result <- transform_result()

  expect_true(is.data.frame(result))
  expect_gt(nrow(result), 0)
  expect_true("retentie" %in% names(result))
  expect_false(anyNA(result$retentie))
})

test_that("transform_data bevat alle verwachte modelvariabelen", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  result <- transform_result()

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
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  result <- transform_result()

  numerieke_vars <- names(result)[sapply(result, is.numeric)]
  expect_false(anyNA(result[, numerieke_vars]))
})

test_that("transform_data filtert correct op opleidingsnaam", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")
  metadata     <- read_metadata()

  # Twee verschillende namen geven twee verschillende aantallen studenten
  result_a <- suppressWarnings(transform_data(
    metadata = metadata, opleidingsnaam = "B Tandheelkunde",
    opleidingsvorm = "VT", eoi = 2010,
    data_ev = data_ev, data_vakhavw = data_vakhavw
  ))
  result_b <- suppressWarnings(transform_data(
    metadata = metadata, opleidingsnaam = "B Bedrijfskunde",
    opleidingsvorm = "VT", eoi = 2010,
    data_ev = data_ev, data_vakhavw = data_vakhavw
  ))

  expect_gt(nrow(result_a), 0)
  expect_gt(nrow(result_b), 0)
  expect_false(nrow(result_a) == nrow(result_b))
})

test_that("read_metadata geeft geen dec_vopl of dec_isat meer terug", {
  metadata <- read_metadata()

  expect_false("dec_vopl" %in% names(metadata))
  expect_false("dec_isat" %in% names(metadata))
  expect_true("dfapcg"             %in% names(metadata))
  expect_true("dfses"              %in% names(metadata))
  expect_true("df_levels"          %in% names(metadata))
  expect_true("variables"          %in% names(metadata))
  expect_true("sensitive_variables" %in% names(metadata))
  expect_true("mapping_newname"    %in% names(metadata))
})

test_that("sensitieve variabelen bevatten geen NA na transformatie", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  result   <- transform_result()
  metadata <- read_metadata()

  for (var in metadata$sensitive_variables) {
    expect_false(
      anyNA(result[[var]]),
      info = paste("NA gevonden in", var)
    )
  }
})
