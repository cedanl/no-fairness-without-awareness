.libPaths(c("C:/Users/caspanij/R/win-library/4.5", .libPaths()))
setwd("C:/Users/caspanij/code/no-fairness-without-awareness")
testthat::test_local(stop_on_failure = FALSE)
