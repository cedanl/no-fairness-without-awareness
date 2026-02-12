test_that("colors_default is exported and has required elements", {
  expect_true(exists("colors_default", envir = asNamespace("nfwa")))
  expect_type(colors_default, "character")
  expect_named(colors_default)

  # Check for essential color names
  essential_colors <- c(
    "positive_color",
    "negative_color",
    "background_color",
    "caption_color",
    "metrics_blue"
  )

  for (color in essential_colors) {
    expect_true(
      color %in% names(colors_default),
      info = paste("Missing essential color:", color)
    )
  }
})

test_that("colors_list is exported and has expected structure", {
  expect_true(exists("colors_list", envir = asNamespace("nfwa")))
  expect_type(colors_list, "list")
  expect_named(colors_list)

  # Check for expected variables
  expected_vars <- c("geslacht", "vooropleiding", "aansluiting")

  for (var in expected_vars) {
    expect_true(
      var %in% names(colors_list),
      info = paste("Missing color palette for:", var)
    )
  }

  # Check that color values are valid hex or named colors
  for (var in expected_vars) {
    palette <- colors_list[[var]]
    expect_type(palette, "character")
    expect_named(palette)
  }
})
