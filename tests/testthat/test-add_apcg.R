test_that("add_apcg joins APCG data correctly", {
  df <- data.frame(
    student_id = 1:3,
    postcodecijfers_student_op_1_oktober = c(1234, 5678, 9012)
  )

  dfapcg <- data.frame(
    cbs_apcg_pc4 = c(1234, 5678),
    cbs_apcg_tf = c(TRUE, FALSE)
  )

  result <- add_apcg(df, dfapcg)

  expect_equal(nrow(result), 3)
  expect_true("cbs_apcg_tf" %in% names(result))
  expect_equal(result$cbs_apcg_tf[1], 1)
  expect_equal(result$cbs_apcg_tf[2], 0)
})

test_that("add_apcg sets missing APCG to 0", {
  df <- data.frame(
    student_id = 1,
    postcodecijfers_student_op_1_oktober = 9999
  )

  dfapcg <- data.frame(
    cbs_apcg_pc4 = 1234,
    cbs_apcg_tf = TRUE
  )

  result <- add_apcg(df, dfapcg)

  # Student with postcode 9999 should get 0
  expect_equal(result$cbs_apcg_tf, 0)
})

test_that("add_apcg converts postcode to integer", {
  df <- data.frame(
    postcodecijfers_student_op_1_oktober = c("1234", "5678")
  )

  dfapcg <- data.frame(
    cbs_apcg_pc4 = integer(0),
    cbs_apcg_tf = logical(0)
  )

  result <- add_apcg(df, dfapcg)

  expect_type(result$postcodecijfers_student_op_1_oktober, "integer")
})

test_that("add_apcg converts TRUE/FALSE to 1/0", {
  df <- data.frame(
    postcodecijfers_student_op_1_oktober = c(1234, 5678)
  )

  dfapcg <- data.frame(
    cbs_apcg_pc4 = c(1234, 5678),
    cbs_apcg_tf = c(TRUE, FALSE)
  )

  result <- add_apcg(df, dfapcg)

  expect_type(result$cbs_apcg_tf, "double")
  expect_equal(result$cbs_apcg_tf, c(1, 0))
})
