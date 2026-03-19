ev_path <- testthat::test_path("../../data/input/EV299XX24_DEMO_enriched.csv")

# Helpers
make_minimal_ev_row <- function(
    opleidingscode_naam_opleiding = "B Tandheelkunde",
    opleidingsvorm = "voltijd",
    eerste_jaar    = 2015,
    inschrijving   = 2015,
    vooropl_omschr = "havo algemeen"
) {
  data.frame(
    persoonsgebonden_nummer                    = 1L,
    inschrijvingsjaar                          = inschrijving,
    instellingscode                            = "21PL",
    actuele_instelling                         = "21PL",
    opleidingscode_naam_opleiding              = opleidingscode_naam_opleiding,
    opleidingsvorm                             = opleidingsvorm,
    eerste_jaar_aan_deze_opleiding_instelling  = eerste_jaar,
    eerste_jaar_aan_deze_instelling            = eerste_jaar,
    eerste_jaar_in_het_hoger_onderwijs         = eerste_jaar,
    diplomajaar_hoogste_vooropleiding          = eerste_jaar - 1L,
    postcodecijfers_student_op_1_oktober       = 1234L,
    geslacht                                   = "vrouw",
    hoogste_vooropleiding_voor_het_ho          = "411",
    hoogste_vooropleiding_voor_het_ho_oorspronkelijke_code = "V0174",
    hoogste_vooropleiding_binnen_het_ho        = "0",
    hoogste_vooropleiding_binnen_het_ho_oorspronkelijke_code = "0",
    hoogste_vooropleiding                      = "411",
    hoogste_vooropleiding_omschrijving         = vooropl_omschr,
    soort_inschrijving_continu_hoger_onderwijs = "hoofdinschrijving binnen het domein hoger onderwijs",
    indicatie_eerstejaars_continu_type_ho_binnen_ho =
      "ingeschrevene is eerstejaars type hoger onderwijs binnen hoger onderwijs voor de betreffende hoofdinschrijving (d.w.z. soort inschrijving continu type ho binnen ho = 1 (of 6 of A))",
    stringsAsFactors = FALSE
  )
}

test_that("transform_ev_data filtert op opleidingsnaam", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev <- read.csv(ev_path, sep = ";")

  result <- suppressWarnings(
    nfwa:::transform_ev_data(data_ev, naam = "B Tandheelkunde", eoi = 2010, vorm = "VT")
  )
  namen <- unique(result$opleidingscode_naam_opleiding)

  expect_true(all(namen == "B Tandheelkunde"))
})

test_that("transform_ev_data herkent enriched opleidingsvorm tekst", {
  df <- make_minimal_ev_row(opleidingsvorm = "voltijd")
  result <- nfwa:::transform_ev_data(df, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  expect_equal(nrow(result), 1L)
})

test_that("transform_ev_data herkent ook legacy numerieke opleidingsvorm", {
  df <- make_minimal_ev_row(opleidingsvorm = 1)
  result <- nfwa:::transform_ev_data(df, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  expect_equal(nrow(result), 1L)
})

test_that("transform_ev_data geeft lege dataframe bij onbekende opleidingsnaam", {
  df <- make_minimal_ev_row(opleidingscode_naam_opleiding = "Onbekende Opleiding")
  result <- nfwa:::transform_ev_data(df, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  expect_equal(nrow(result), 0L)
})

test_that("vooropleiding classificatie werkt op basis van omschrijving kolom", {
  cases <- list(
    list(omschr = "havo algemeen",        verwacht = "HAVO"),
    list(omschr = "vwo algemeen",         verwacht = "VWO"),
    list(omschr = "mbo niveau 4",         verwacht = "MBO"),
    list(omschr = "hbo bachelor",         verwacht = "HO"),
    list(omschr = "wo bachelor",          verwacht = "HO"),
    list(omschr = "buitenlands diploma",  verwacht = "BD"),
    list(omschr = "overig",               verwacht = "Overig"),
    list(omschr = "",                     verwacht = "Onbekend")
  )

  for (case in cases) {
    df <- make_minimal_ev_row(vooropl_omschr = case$omschr)
    result <- nfwa:::transform_ev_data(df, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
    expect_equal(
      as.character(result$vooropleiding),
      case$verwacht,
      info = paste("omschrijving:", case$omschr)
    )
  }
})

test_that("is_2e_studie detecteert echte neveninschrijving in enriched tekst", {
  df_hoofd <- make_minimal_ev_row()
  df_hoofd$soort_inschrijving_continu_hoger_onderwijs <-
    "hoofdinschrijving binnen het domein hoger onderwijs"

  df_neven <- make_minimal_ev_row()
  df_neven$soort_inschrijving_continu_hoger_onderwijs <-
    "neveninschrijving binnen het domein hoger onderwijs (combinatie opleiding-instelling komt NIET voor bij een andere inschrijving van de betreffende student) (echte neveninschrijving)"

  r_hoofd <- nfwa:::transform_ev_data(df_hoofd, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  r_neven <- nfwa:::transform_ev_data(df_neven, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")

  expect_false(r_hoofd$is_2e_studie)
  expect_true(r_neven$is_2e_studie)
})

test_that("indicatie_eerstejaars_type detecteert eerstejaars in enriched tekst", {
  df_eerste <- make_minimal_ev_row()
  df_eerste$indicatie_eerstejaars_continu_type_ho_binnen_ho <-
    "ingeschrevene is eerstejaars type hoger onderwijs binnen hoger onderwijs voor de betreffende hoofdinschrijving (d.w.z. soort inschrijving continu type ho binnen ho = 1 (of 6 of A))"

  df_hoger <- make_minimal_ev_row()
  df_hoger$indicatie_eerstejaars_continu_type_ho_binnen_ho <-
    "ingeschrevene is hogerejaars type hoger onderwijs binnen hoger onderwijs voor de betreffende hoofdinschrijving (d.w.z. soort inschrijving continu type ho binnen ho = 1 (of 6 of A))"

  r_eerste <- nfwa:::transform_ev_data(df_eerste, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  r_hoger  <- nfwa:::transform_ev_data(df_hoger,  naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")

  expect_true(r_eerste$indicatie_eerstejaars_type)
  expect_false(r_hoger$indicatie_eerstejaars_type)
})

test_that("transform_ev_data bevat kolom aansluiting als factor", {
  skip_if_not(file.exists(ev_path), "Enriched demo data niet beschikbaar")

  data_ev <- read.csv(ev_path, sep = ";")
  result  <- suppressWarnings(
    nfwa:::transform_ev_data(data_ev, naam = "B Tandheelkunde", eoi = 2010, vorm = "VT")
  )

  expect_true("aansluiting" %in% names(result))
  expect_true(is.factor(result$aansluiting))
  expect_true(all(levels(result$aansluiting) %in%
    c("Direct", "Tussenjaar", "Switch intern", "Switch extern",
      "2e Studie", "Na CD", "Overig", "Onbekend")))
})

test_that("geslacht wordt gerecodeert naar M/V", {
  df_man   <- make_minimal_ev_row(); df_man$geslacht   <- "man"
  df_vrouw <- make_minimal_ev_row(); df_vrouw$geslacht <- "vrouw"
  df_M     <- make_minimal_ev_row(); df_M$geslacht     <- "M"

  r_man   <- nfwa:::transform_ev_data(df_man,   naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  r_vrouw <- nfwa:::transform_ev_data(df_vrouw, naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")
  r_M     <- nfwa:::transform_ev_data(df_M,     naam = "B Tandheelkunde", eoi = 2015, vorm = "VT")

  expect_equal(r_man$geslacht,   "M")
  expect_equal(r_vrouw$geslacht, "V")
  expect_equal(r_M$geslacht,     "M")
})
