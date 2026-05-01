# S3 + PostgreSQL storage backend
#
# Reads tabular data from PostgreSQL and files from S3-compatible storage
# (e.g. MinIO). All configuration is via environment variables — see
# ?nfwa_storage for the full list.

storage_s3pg <- function() {
  check_s3pg_packages()

  s3_endpoint  <- Sys.getenv("NFWA_S3_ENDPOINT", "http://localhost:9000")
  s3_bucket    <- Sys.getenv("NFWA_S3_BUCKET", "nfwa")
  s3_region    <- Sys.getenv("NFWA_S3_REGION", "")
  s3_access    <- Sys.getenv("NFWA_S3_ACCESS_KEY", "")
  s3_secret    <- Sys.getenv("NFWA_S3_SECRET_KEY", "")

  pg_con <- NULL

  get_pg_con <- function() {
    if (is.null(pg_con) || !DBI::dbIsValid(pg_con)) {
      pg_con <<- DBI::dbConnect(
        RPostgres::Postgres(),
        host     = Sys.getenv("NFWA_PG_HOST", "localhost"),
        port     = as.integer(Sys.getenv("NFWA_PG_PORT", "5432")),
        dbname   = Sys.getenv("NFWA_PG_DBNAME", "nfwa"),
        user     = Sys.getenv("NFWA_PG_USER", "nfwa"),
        password = Sys.getenv("NFWA_PG_PASSWORD", "")
      )
    }
    pg_con
  }

  s3_put <- function(file, key) {
    aws.s3::put_object(
      file       = file,
      object     = key,
      bucket     = s3_bucket,
      base_url   = sub("^https?://", "", s3_endpoint),
      region     = s3_region,
      key        = s3_access,
      secret     = s3_secret,
      use_https  = grepl("^https://", s3_endpoint)
    )
  }

  s3_get <- function(key, dest) {
    aws.s3::save_object(
      object     = key,
      bucket     = s3_bucket,
      file       = dest,
      base_url   = sub("^https?://", "", s3_endpoint),
      region     = s3_region,
      key        = s3_access,
      secret     = s3_secret,
      use_https  = grepl("^https://", s3_endpoint)
    )
  }

  list(
    read_csv = function(path, ...) {
      if (grepl("^pg://", path)) {
        table_name <- sub("^pg://", "", path)
        con <- get_pg_con()
        DBI::dbReadTable(con, table_name)

      } else if (grepl("^s3://", path)) {
        key <- sub("^s3://[^/]+/", "", path)
        tmp <- tempfile(fileext = ".csv")
        on.exit(unlink(tmp), add = TRUE)
        s3_get(key, tmp)
        read.csv(tmp, sep = ";", stringsAsFactors = FALSE, ...)

      } else {
        read.csv(path, sep = ";", stringsAsFactors = FALSE, ...)
      }
    },

    persist_outputs = function(temp_dir = "temp", pdf_path = NULL, prefix = "") {
      uploaded <- character(0)

      if (dir.exists(temp_dir)) {
        files <- list.files(temp_dir, full.names = TRUE)
        for (f in files) {
          key <- if (nchar(prefix) > 0) {
            paste(prefix, "temp", basename(f), sep = "/")
          } else {
            paste("temp", basename(f), sep = "/")
          }
          s3_put(f, key)
          uploaded <- c(uploaded, key)
        }
      }

      if (!is.null(pdf_path) && file.exists(pdf_path)) {
        key <- if (nchar(prefix) > 0) {
          paste(prefix, basename(pdf_path), sep = "/")
        } else {
          basename(pdf_path)
        }
        s3_put(pdf_path, key)
        uploaded <- c(uploaded, key)
      }

      message("Ge\u00fcpload naar S3: ", length(uploaded), " bestanden")
      invisible(list(temp_dir = temp_dir, pdf_path = pdf_path,
                     uploaded = uploaded))
    },

    write_table = function(df, table_name, overwrite = FALSE) {
      con <- get_pg_con()
      DBI::dbWriteTable(con, table_name, df, overwrite = overwrite)
    },

    read_table = function(table_name) {
      con <- get_pg_con()
      DBI::dbReadTable(con, table_name)
    },

    disconnect = function() {
      if (!is.null(pg_con) && DBI::dbIsValid(pg_con)) {
        DBI::dbDisconnect(pg_con)
        pg_con <<- NULL
      }
    },

    type = "s3pg"
  )
}


check_s3pg_packages <- function() {
  missing <- character(0)
  if (!requireNamespace("aws.s3", quietly = TRUE))
    missing <- c(missing, "aws.s3")
  if (!requireNamespace("DBI", quietly = TRUE))
    missing <- c(missing, "DBI")
  if (!requireNamespace("RPostgres", quietly = TRUE))
    missing <- c(missing, "RPostgres")

  if (length(missing) > 0) {
    stop(
      "De volgende packages zijn vereist voor de s3pg backend:\n  ",
      paste(missing, collapse = ", "),
      "\nInstalleer met: install.packages(c(",
      paste0('"', missing, '"', collapse = ", "), "))"
    )
  }
}
