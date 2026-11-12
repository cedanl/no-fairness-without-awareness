userlib <- "C:/Users/caspanij/R/win-library/4.5"
.libPaths(c(userlib, .libPaths()))

pak::pak(
  c("local::.", "any::withr", "any::aws.s3", "any::DBI", "any::RPostgres"),
  lib = userlib
)
