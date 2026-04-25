# --- nfwa_storage() dispatcher ------------------------------------------------

test_that("nfwa_storage() standaard file backend", {
  s <- nfwa_storage()
  expect_equal(s$type, "file")
  expect_type(s$read_csv, "closure")
  expect_type(s$persist_outputs, "closure")
})

test_that("nfwa_storage() explicit file backend", {
  s <- nfwa_storage("file")
  expect_equal(s$type, "file")
})

test_that("nfwa_storage() error bij onbekende backend", {
  expect_error(nfwa_storage("foobar"), "Onbekende storage backend")
})

test_that("nfwa_storage() leest NFWA_STORAGE_BACKEND env var", {
  withr::with_envvar(c(NFWA_STORAGE_BACKEND = "file"), {
    s <- nfwa_storage()
    expect_equal(s$type, "file")
  })
})

test_that("nfwa_storage() error bij s3pg zonder packages", {
  skip_if(requireNamespace("aws.s3", quietly = TRUE) &&
          requireNamespace("DBI", quietly = TRUE) &&
          requireNamespace("RPostgres", quietly = TRUE),
          "s3pg packages zijn geinstalleerd, kan ontbreken niet testen")

  expect_error(nfwa_storage("s3pg"), "vereist")
})

# --- File backend: read_csv ---------------------------------------------------

test_that("file backend read_csv leest CSV correct", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines("a;b;c\n1;2;3\n4;5;6", tmp)

  s <- nfwa_storage("file")
  df <- s$read_csv(tmp)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_equal(names(df), c("a", "b", "c"))
})

test_that("file backend read_csv error bij ontbrekend bestand", {
  s <- nfwa_storage("file")
  expect_error(s$read_csv("/nonexistent/path.csv"), "niet gevonden")
})

# --- File backend: persist_outputs -------------------------------------------

test_that("file backend persist_outputs is no-op", {
  s <- nfwa_storage("file")
  result <- s$persist_outputs(temp_dir = "temp", pdf_path = NULL)
  expect_type(result, "list")
  expect_null(result$pdf_path)
})

# --- analyze_fairness accepts storage parameter ------------------------------

test_that("analyze_fairness accepteert storage parameter", {
  df <- data.frame(x = 1)
  s <- nfwa_storage("file")

  err <- tryCatch(
    analyze_fairness(
      data_ev        = df,
      data_vakhavw   = df,
      opleidingsnaam = "Test",
      eoi            = 2020,
      opleidingsvorm = "VT",
      generate_pdf   = FALSE,
      storage        = s
    ),
    error = function(e) e
  )

  if (inherits(err, "error")) {
    expect_false(
      grepl("storage", conditionMessage(err), ignore.case = TRUE),
      info = "Fout mag niet gerelateerd zijn aan de storage parameter"
    )
  }
})
