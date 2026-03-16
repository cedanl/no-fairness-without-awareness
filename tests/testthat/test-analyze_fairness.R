test_that("analyze_fairness geeft error bij ongeldige opleidingsvorm", {
  df <- data.frame(x = 1)

  expect_error(
    analyze_fairness(
      data_ev = df,
      data_vakhavw = df,
      opleidingsnaam = "Test",
      eoi = 2020,
      opleidingsvorm = "XX",
      generate_pdf = FALSE
    ),
    "opleidingsvorm"
  )
})

test_that("analyze_fairness geeft error als data_ev geen data frame is", {
  expect_error(
    analyze_fairness(
      data_ev = "geen dataframe",
      data_vakhavw = data.frame(x = 1),
      opleidingsnaam = "Test",
      eoi = 2020,
      opleidingsvorm = "VT",
      generate_pdf = FALSE
    ),
    "data_ev"
  )
})

test_that("analyze_fairness geeft error als data_vakhavw geen data frame is", {
  expect_error(
    analyze_fairness(
      data_ev = data.frame(x = 1),
      data_vakhavw = list(x = 1),
      opleidingsnaam = "Test",
      eoi = 2020,
      opleidingsvorm = "VT",
      generate_pdf = FALSE
    ),
    "data_vakhavw"
  )
})

test_that("analyze_fairness accepteert alle geldige opleidingsvormen", {
  # Alleen validatie testen — geen echte data nodig
  # De functie faalt pas bij transform_data, niet bij de inputcheck
  for (vorm in c("VT", "DT", "DU")) {
    expect_no_error(
      tryCatch(
        analyze_fairness(
          data_ev = data.frame(x = 1),
          data_vakhavw = data.frame(x = 1),
          opleidingsnaam = "Test",
          eoi = 2020,
          opleidingsvorm = vorm,
          generate_pdf = FALSE
        ),
        error = function(e) {
          # Alleen opleidingsvorm-fout is hier een testfailure
          if (grepl("opleidingsvorm", conditionMessage(e))) stop(e)
          NULL
        }
      )
    )
  }
})
