test_that("analyze_fairness geeft error bij ongeldige opleidingsvorm", {
  df <- data.frame(x = 1)

  expect_error(
    analyze_fairness(
      data_ev        = df,
      data_vakhavw   = df,
      opleidingsnaam = "Test",
      eoi            = 2020,
      opleidingsvorm = "XX",
      generate_pdf   = FALSE
    ),
    "opleidingsvorm"
  )
})

test_that("analyze_fairness geeft error als data_ev geen data frame is", {
  expect_error(
    analyze_fairness(
      data_ev        = "geen dataframe",
      data_vakhavw   = data.frame(x = 1),
      opleidingsnaam = "Test",
      eoi            = 2020,
      opleidingsvorm = "VT",
      generate_pdf   = FALSE
    ),
    "data_ev"
  )
})

test_that("analyze_fairness geeft error als data_vakhavw geen data frame is", {
  expect_error(
    analyze_fairness(
      data_ev        = data.frame(x = 1),
      data_vakhavw   = list(x = 1),
      opleidingsnaam = "Test",
      eoi            = 2020,
      opleidingsvorm = "VT",
      generate_pdf   = FALSE
    ),
    "data_vakhavw"
  )
})

test_that("analyze_fairness geeft error bij 0 studenten na filtering", {
  ev_path      <- testthat::test_path("../../data/input/EV299XX24_DEMO_enriched.csv")
  vakhavw_path <- testthat::test_path("../../data/input/VAKHAVW_99XX_DEMO_enriched.csv")
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev      <- read.csv(ev_path, sep = ";")
  data_vakhavw <- read.csv(vakhavw_path, sep = ";")

  expect_error(
    analyze_fairness(
      data_ev        = data_ev,
      data_vakhavw   = data_vakhavw,
      opleidingsnaam = "B Tandheelkunde",
      eoi            = 2099,
      opleidingsvorm = "VT",
      generate_pdf   = FALSE
    ),
    "Analyse gestopt: geen studenten gevonden na filtering."
  )
})

test_that("analyze_fairness accepteert alle geldige opleidingsvormen", {
  # Test alleen de input-validatie: "VT", "DT" en "DU" mogen niet falen op opleidingsvorm.
  # De functie zal later falen vanwege ongeldige data, maar dat is verwacht gedrag.
  for (vorm in c("VT", "DT", "DU")) {
    err <- tryCatch(
      analyze_fairness(
        data_ev        = data.frame(x = 1),
        data_vakhavw   = data.frame(x = 1),
        opleidingsnaam = "Test",
        eoi            = 2020,
        opleidingsvorm = vorm,
        generate_pdf   = FALSE
      ),
      error = function(e) e
    )

    # De validatiecheck op opleidingsvorm zelf mag nooit falen
    if (inherits(err, "error")) {
      expect_false(
        grepl("opleidingsvorm moet", conditionMessage(err)),
        info = paste("Onverwachte opleidingsvorm-fout voor vorm:", vorm)
      )
    }
  }
})
