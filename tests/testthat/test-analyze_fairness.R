test_that("analyze_fairness geeft error bij ongeldige opleidingsvorm", {
  df <- data.frame(x = 1)

  expect_error(
    analyze_fairness(
      data_ev        = df,
      data_vakhavw   = df,
      opleidingscode = 60048,
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
      opleidingscode = 60048,
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
      opleidingscode = 60048,
      opleidingsnaam = "Test",
      eoi            = 2020,
      opleidingsvorm = "VT",
      generate_pdf   = FALSE
    ),
    "data_vakhavw"
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
        opleidingscode = 60048,
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
