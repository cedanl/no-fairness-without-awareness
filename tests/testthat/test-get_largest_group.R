test_that("get_largest_group returns the most common value", {
  df <- data.frame(
    geslacht = c("M", "M", "M", "V", "V"),
    vooropleiding = c("HAVO", "VWO", "HAVO", "HAVO", "VWO")
  )

  expect_equal(get_largest_group(df, "geslacht"), "M")
  expect_equal(get_largest_group(df, "vooropleiding"), "HAVO")
})

test_that("get_largest_group handles ties by returning the first", {
  df <- data.frame(
    group = c("A", "A", "B", "B")
  )

  result <- get_largest_group(df, "group")
  expect_true(result %in% c("A", "B"))
  expect_length(result, 1)
})

test_that("get_largest_group handles NA values", {
  df <- data.frame(
    group = c("A", "A", "B", NA, NA, NA)
  )

  # Should return "A" or "B", not NA
  result <- get_largest_group(df, "group")
  expect_false(is.na(result))
})

test_that("get_largest_group works with single value", {
  df <- data.frame(
    group = c("A", "A", "A")
  )

  expect_equal(get_largest_group(df, "group"), "A")
})
