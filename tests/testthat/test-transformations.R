test_that("transform_vakhavw aggregates grades correctly", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("tidyr")

  df_vak <- data.frame(
    persoonsgebonden_nummer = c(1L, 1L, 2L, 2L),
    afkorting_vak = c("wisA", "netl", "wisA", "entl"),
    cijfer_eerste_centraal_examen = c(7.0, 8.0, 6.0, 9.0),
    gemiddeld_cijfer_cijferlijst = c(7.5, 7.5, 6.5, 6.5),
    cijfer_schoolexamen = c(7.2, 8.1, 5.9, 8.8),
    stringsAsFactors = FALSE
  )

  result <- nfwa:::transform_vakhavw(df_vak)

  expect_true("persoonsgebonden_nummer" %in% names(result))
  expect_true("wis" %in% names(result))
  expect_equal(nrow(result), 2L)
  # Student 1 has wisA=7, student 2 has wisA=6
  expect_equal(result$wis[result$persoonsgebonden_nummer == 1], 7.0)
  expect_equal(result$wis[result$persoonsgebonden_nummer == 2], 6.0)
})

test_that("transform_ev_data filters on education name and form", {
  # Build a small mock dataset with 3 students:
  # - student 1: B Tandheelkunde VT, start 2020 (match)
  # - student 2: B Tandheelkunde VT, start 2020, also year 2021 (match, has retentie)
  # - student 3: B Bedrijfskunde VT, start 2020 (wrong opleiding)
  make_row <- function(pgn, naam, vorm, eerste_jaar, inschrijving) {
    data.frame(
      persoonsgebonden_nummer = pgn,
      inschrijvingsjaar = inschrijving,
      opleidingscode_naam_opleiding = naam,
      opleidingsvorm = vorm,
      eerste_jaar_aan_deze_opleiding_instelling = eerste_jaar,
      eerste_jaar_aan_deze_instelling = eerste_jaar,
      eerste_jaar_in_het_hoger_onderwijs = eerste_jaar,
      diplomajaar_hoogste_vooropleiding = eerste_jaar - 1L,
      postcodecijfers_student_op_1_oktober = 1234L,
      geslacht = "vrouw",
      hoogste_vooropleiding_omschrijving = "havo algemeen",
      soort_inschrijving_continu_hoger_onderwijs = "hoofdinschrijving binnen het domein hoger onderwijs",
      indicatie_eerstejaars_continu_type_ho_binnen_ho = "ingeschrevene is eerstejaars type hoger onderwijs binnen hoger onderwijs voor de betreffende hoofdinschrijving (d.w.z. soort inschrijving continu type ho binnen ho = 1 (of 6 of A))",
      datum_inschrijving = paste0(inschrijving, "0901"),
      stringsAsFactors = FALSE
    )
  }

  mock_ev <- rbind(
    make_row(1L, "B Tandheelkunde", "voltijd", 2020L, 2020L),
    make_row(2L, "B Tandheelkunde", "voltijd", 2020L, 2020L),
    make_row(2L, "B Tandheelkunde", "voltijd", 2020L, 2021L),
    make_row(3L, "B Bedrijfskunde", "voltijd", 2020L, 2020L)
  )

  result <- nfwa:::transform_ev_data(mock_ev, naam = "B Tandheelkunde", eoi = 2020, vorm = "VT")

  # Only students 1 and 2 should remain (filtered on opleiding)
  expect_equal(sort(unique(result$persoonsgebonden_nummer)), c(1L, 2L))
  # Student 2 has retentie (enrolled in year+1), student 1 does not
  expect_false(result$retentie[result$persoonsgebonden_nummer == 1])
  expect_true(result$retentie[result$persoonsgebonden_nummer == 2])
})

test_that("transform_1cho_data combines student and grade data", {
  # Create minimal EV-transformed data (as if transform_ev_data already ran)
  df_ev <- data.frame(
    persoonsgebonden_nummer = c(1L, 2L),
    inschrijvingsjaar = c(2020L, 2020L),
    datum_inschrijving = c("20200901", "20200915"),
    geslacht = factor(c("V", "M")),
    retentie = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  # Create minimal vakhavw-transformed data (as if transform_vakhavw already ran)
  df_vak <- data.frame(
    persoonsgebonden_nummer = c(1L, 2L),
    gemiddeld_cijfer_cijferlijst = c(7.5, 6.0),
    cijfer_schoolexamen = c(7.0, 5.5),
    wisA = c(8.0, NA),
    wis = c(8.0, NA),
    stringsAsFactors = FALSE
  )

  result <- nfwa:::transform_1cho_data(df_ev, df_vak)

  # Should have both students
  expect_equal(nrow(result), 2L)
  # Grade data should be joined
  expect_true("gemiddeld_cijfer_cijferlijst" %in% names(result))
  expect_true("wis" %in% names(result))
  # Student 1 should have wis=8
  expect_equal(result$wis[result$persoonsgebonden_nummer == 1], 8.0)
  # datum_inschrijving should be converted to Date
  expect_true(inherits(result$datum_inschrijving, "Date"))
  # dagen_tussen_inschrijving_1_september should be calculated
  expect_true("dagen_tussen_inschrijving_1_september" %in% names(result))
  expect_equal(result$dagen_tussen_inschrijving_1_september[result$persoonsgebonden_nummer == 1], 0L)
  # retentie (logical) should be converted to integer
  expect_true(is.integer(result$retentie))
})
