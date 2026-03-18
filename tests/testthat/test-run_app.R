test_that("run_app is exported and exists", {
  expect_true(is.function(nfwa::run_app))
})

test_that("run_app app directory exists via system.file", {
  app_dir <- system.file("shiny-app", package = "nfwa")
  expect_true(nchar(app_dir) > 0)
  expect_true(dir.exists(app_dir))
})

test_that("run_app geeft foutmelding als shiny niet beschikbaar is", {
  skip_if_not_installed("mockery")
  mockery::stub(run_app, "requireNamespace", function(pkg, quietly) {
    if (pkg == "shiny") return(FALSE)
    TRUE
  })
  expect_error(run_app(), "shiny")
})
