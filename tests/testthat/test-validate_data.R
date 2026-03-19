ev_path      <- testthat::test_path("../../data/input/EV299XX24_DEMO_enriched.csv")
vakhavw_path <- testthat::test_path("../../data/input/VAKHAVW_99XX_DEMO_enriched.csv")

test_that("validate_data slaagt met correcte data", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")

  expect_true(
    nfwa:::validate_data(data_ev, data_vakhavw, "B Tandheelkunde", "VT")
  )
})

test_that("validate_data meldt ontbrekende EV-kolommen", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")[, 1:3]
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "B Tandheelkunde", "VT"),
    "Ontbrekende kolommen in data_ev"
  )
})

test_that("validate_data meldt ontbrekende VAKHAVW-kolommen", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")[, 1:2]

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "B Tandheelkunde", "VT"),
    "Ontbrekende kolommen in data_vakhavw"
  )
})

test_that("validate_data meldt onbekende opleidingsnaam met suggesties", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "Onzin Opleiding", "VT"),
    "niet gevonden.*Beschikbare opleidingen"
  )
})

test_that("validate_data meldt verkeerde opleidingsvorm", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "B Tandheelkunde", "DU"),
    "niet beschikbaar.*Beschikbare vormen"
  )
})

test_that("validate_data meldt niet-numerieke cijferkolommen", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")
  data_vakhavw$cijfer_eerste_centraal_examen <- "tekst"

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "B Tandheelkunde", "VT"),
    "geen numerieke waarden"
  )
})

test_that("validate_data meldt meerdere problemen tegelijk", {
  data_ev      <- data.frame(x = 1)
  data_vakhavw <- data.frame(y = 1)

  expect_error(
    nfwa:::validate_data(data_ev, data_vakhavw, "Test", "VT"),
    "Ontbrekende kolommen in data_ev.*Ontbrekende kolommen in data_vakhavw"
  )
})
