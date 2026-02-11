test_that("add_ses joins SES data correctly", {
  df <- data.frame(
    student_id = 1:3,
    postcodecijfers_student_op_1_oktober = c(1234, 5678, 9012)
  )

  dfses <- data.frame(
    ses_pc4 = c(1234, 5678),
    ses_verslagjaar = c(2022, 2022),
    ses_inkomen = c(30000, 40000)
  )

  result <- add_ses(df, dfses)

  expect_equal(nrow(result), 3)
  expect_true("ses_inkomen" %in% names(result))
  expect_equal(result$ses_inkomen[1], 30000)
  expect_equal(result$ses_inkomen[2], 40000)
  expect_true(is.na(result$ses_inkomen[3]))
})

test_that("add_ses selects most recent year when duplicates exist", {
  df <- data.frame(
    student_id = 1,
    postcodecijfers_student_op_1_oktober = 1234
  )

  dfses <- data.frame(
    ses_pc4 = c(1234, 1234),
    ses_verslagjaar = c(2021, 2022),
    ses_inkomen = c(25000, 30000)
  )

  result <- add_ses(df, dfses)

  # Should select 2022 data
  expect_equal(result$ses_inkomen, 30000)
})

test_that("add_ses converts postcode to integer", {
  df <- data.frame(
    postcodecijfers_student_op_1_oktober = c("1234", "5678")
  )

  dfses <- data.frame(
    ses_pc4 = integer(0),
    ses_verslagjaar = integer(0)
  )

  result <- add_ses(df, dfses)

  expect_type(result$postcodecijfers_student_op_1_oktober, "integer")
})
