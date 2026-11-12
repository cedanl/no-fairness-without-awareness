options(download.file.method = "wget", download.file.extra = "--no-check-certificate")
setwd("/app")
deps <- remotes::dev_package_deps(".", dependencies = TRUE)
missing <- deps[deps$is_missing, ]
cat("Missing packages:\n")
print(missing[, c("package", "version")])
