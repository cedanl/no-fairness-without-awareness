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

test_that("nfwa_storage() empty env var defaults to file", {
  withr::with_envvar(c(NFWA_STORAGE_BACKEND = ""), {
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

test_that("file backend read_csv passes extra arguments", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines("a;b;c\n1;2;3\n4;5;6", tmp)

  s <- nfwa_storage("file")
  df <- s$read_csv(tmp, nrows = 1)
  expect_equal(nrow(df), 1)
})

# --- File backend: persist_outputs -------------------------------------------

test_that("file backend persist_outputs is no-op", {
  s <- nfwa_storage("file")
  result <- s$persist_outputs(temp_dir = "temp", pdf_path = NULL)
  expect_type(result, "list")
  expect_null(result$pdf_path)
})

test_that("file backend persist_outputs returns temp_dir and pdf_path", {
  s <- nfwa_storage("file")
  result <- s$persist_outputs(temp_dir = "/some/dir", pdf_path = "/some/file.pdf",
                              prefix = "test")
  expect_equal(result$temp_dir, "/some/dir")
  expect_equal(result$pdf_path, "/some/file.pdf")
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

# --- check_s3pg_packages -----------------------------------------------------

test_that("check_s3pg_packages passes when all packages available", {
  skip_if_not(requireNamespace("aws.s3", quietly = TRUE), "aws.s3 not installed")
  skip_if_not(requireNamespace("DBI", quietly = TRUE), "DBI not installed")
  skip_if_not(requireNamespace("RPostgres", quietly = TRUE), "RPostgres not installed")

  expect_no_error(nfwa:::check_s3pg_packages())
})

# --- S3+PG backend: unit tests (mocked) --------------------------------------

test_that("s3pg backend has correct type and methods", {
  skip_if_not(requireNamespace("aws.s3", quietly = TRUE), "aws.s3 not installed")
  skip_if_not(requireNamespace("DBI", quietly = TRUE), "DBI not installed")
  skip_if_not(requireNamespace("RPostgres", quietly = TRUE), "RPostgres not installed")

  withr::with_envvar(c(
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "test",
    NFWA_S3_SECRET_KEY = "test",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa"
  ), {
    s <- nfwa_storage("s3pg")
    expect_equal(s$type, "s3pg")
    expect_type(s$read_csv, "closure")
    expect_type(s$persist_outputs, "closure")
    expect_type(s$write_table, "closure")
    expect_type(s$read_table, "closure")
    expect_type(s$disconnect, "closure")
  })
})

test_that("s3pg read_csv falls back to local file for plain paths", {
  skip_if_not(requireNamespace("aws.s3", quietly = TRUE), "aws.s3 not installed")
  skip_if_not(requireNamespace("DBI", quietly = TRUE), "DBI not installed")
  skip_if_not(requireNamespace("RPostgres", quietly = TRUE), "RPostgres not installed")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  writeLines("x;y\n10;20\n30;40", tmp)

  s <- nfwa_storage("s3pg")
  df <- s$read_csv(tmp)
  expect_equal(nrow(df), 2)
  expect_equal(names(df), c("x", "y"))
})

# --- S3+PG backend: integration tests (require Docker services) ---------------

skip_if_no_docker_pg <- function() {
  skip_if_not(requireNamespace("DBI", quietly = TRUE), "DBI not installed")
  skip_if_not(requireNamespace("RPostgres", quietly = TRUE), "RPostgres not installed")
  tryCatch({
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      host = "localhost", port = 5432,
      dbname = "nfwa", user = "nfwa", password = "nfwa"
    )
    DBI::dbDisconnect(con)
  }, error = function(e) {
    skip("PostgreSQL not available on localhost:5432 (start with docker compose up -d)")
  })
}

skip_if_no_docker_minio <- function() {
  skip_if_not(requireNamespace("aws.s3", quietly = TRUE), "aws.s3 not installed")
  tryCatch({
    con <- url("http://localhost:9000/minio/health/live", open = "rb")
    on.exit(close(con))
    readLines(con, n = 1, warn = FALSE)
  }, error = function(e) {
    skip("MinIO not available on localhost:9000 (start with docker compose up -d)")
  })
}

test_that("integration: PG write_table and read_table roundtrip", {
  skip_if_no_docker_pg()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    test_df <- data.frame(
      id = 1:5,
      naam = c("Alice", "Bob", "Charlie", "Diana", "Eve"),
      score = c(7.5, 8.0, 6.5, 9.0, 7.0),
      stringsAsFactors = FALSE
    )

    s$write_table(test_df, "test_roundtrip", overwrite = TRUE)
    result <- s$read_table("test_roundtrip")

    expect_equal(nrow(result), 5)
    expect_true("naam" %in% names(result))
    expect_equal(result$score, test_df$score)

    # cleanup
    con <- DBI::dbConnect(RPostgres::Postgres(),
      host = "localhost", port = 5432, dbname = "nfwa",
      user = "nfwa", password = "nfwa")
    DBI::dbRemoveTable(con, "test_roundtrip")
    DBI::dbDisconnect(con)
  })
})

test_that("integration: PG write_table overwrite replaces data", {
  skip_if_no_docker_pg()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    df1 <- data.frame(x = 1:3)
    df2 <- data.frame(x = 10:12, y = c("a", "b", "c"), stringsAsFactors = FALSE)

    s$write_table(df1, "test_overwrite", overwrite = TRUE)
    s$write_table(df2, "test_overwrite", overwrite = TRUE)
    result <- s$read_table("test_overwrite")

    expect_equal(nrow(result), 3)
    expect_true("y" %in% names(result))
    expect_equal(result$x, 10:12)

    con <- DBI::dbConnect(RPostgres::Postgres(),
      host = "localhost", port = 5432, dbname = "nfwa",
      user = "nfwa", password = "nfwa")
    DBI::dbRemoveTable(con, "test_overwrite")
    DBI::dbDisconnect(con)
  })
})

test_that("integration: PG read_csv with pg:// prefix", {
  skip_if_no_docker_pg()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    test_df <- data.frame(a = c(1, 2), b = c("x", "y"), stringsAsFactors = FALSE)
    s$write_table(test_df, "test_read_csv_pg", overwrite = TRUE)

    result <- s$read_csv("pg://test_read_csv_pg")
    expect_equal(nrow(result), 2)
    expect_true("b" %in% names(result))

    con <- DBI::dbConnect(RPostgres::Postgres(),
      host = "localhost", port = 5432, dbname = "nfwa",
      user = "nfwa", password = "nfwa")
    DBI::dbRemoveTable(con, "test_read_csv_pg")
    DBI::dbDisconnect(con)
  })
})

test_that("integration: PG disconnect closes connection", {
  skip_if_no_docker_pg()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    # Force a connection by reading
    s$write_table(data.frame(x = 1), "test_disconnect", overwrite = TRUE)

    s$disconnect()
    # After disconnect, a new call should reconnect automatically
    result <- s$read_table("test_disconnect")
    expect_equal(nrow(result), 1)
    s$disconnect()

    con <- DBI::dbConnect(RPostgres::Postgres(),
      host = "localhost", port = 5432, dbname = "nfwa",
      user = "nfwa", password = "nfwa")
    DBI::dbRemoveTable(con, "test_disconnect")
    DBI::dbDisconnect(con)
  })
})

test_that("integration: S3 persist_outputs uploads files to MinIO", {
  skip_if_no_docker_pg()
  skip_if_no_docker_minio()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    tmp_dir <- tempfile("nfwa_test_")
    dir.create(tmp_dir)
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
    writeLines("test content 1", file.path(tmp_dir, "plot1.png"))
    writeLines("test content 2", file.path(tmp_dir, "plot2.png"))

    pdf_file <- tempfile(fileext = ".pdf")
    on.exit(unlink(pdf_file), add = TRUE)
    writeLines("fake pdf", pdf_file)

    result <- s$persist_outputs(
      temp_dir = tmp_dir,
      pdf_path = pdf_file,
      prefix = "test_integration"
    )

    expect_equal(length(result$uploaded), 3)
    expect_true(any(grepl("plot1.png", result$uploaded)))
    expect_true(any(grepl("plot2.png", result$uploaded)))
    expect_true(any(grepl("\\.pdf$", result$uploaded)))
  })
})

test_that("integration: S3 persist_outputs with empty dir uploads nothing", {
  skip_if_no_docker_pg()
  skip_if_no_docker_minio()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    tmp_dir <- tempfile("nfwa_empty_")
    dir.create(tmp_dir)
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

    result <- s$persist_outputs(temp_dir = tmp_dir, pdf_path = NULL, prefix = "empty")
    expect_equal(length(result$uploaded), 0)
  })
})

test_that("integration: S3 persist_outputs with nonexistent dir and no pdf", {
  skip_if_no_docker_pg()
  skip_if_no_docker_minio()

  withr::with_envvar(c(
    NFWA_STORAGE_BACKEND = "s3pg",
    NFWA_PG_HOST = "localhost",
    NFWA_PG_PORT = "5432",
    NFWA_PG_DBNAME = "nfwa",
    NFWA_PG_USER = "nfwa",
    NFWA_PG_PASSWORD = "nfwa",
    NFWA_S3_ENDPOINT = "http://localhost:9000",
    NFWA_S3_BUCKET = "nfwa",
    NFWA_S3_REGION = "",
    NFWA_S3_ACCESS_KEY = "minioadmin",
    NFWA_S3_SECRET_KEY = "minioadmin"
  ), {
    s <- nfwa_storage("s3pg")
    on.exit(s$disconnect(), add = TRUE)

    result <- s$persist_outputs(
      temp_dir = "/nonexistent/dir",
      pdf_path = "/nonexistent/file.pdf",
      prefix = "noexist"
    )
    expect_equal(length(result$uploaded), 0)
  })
})
