# Renv settings
Sys.setenv(
  # To not distract beginner users
  RENV_CONFIG_STARTUP_QUIET = TRUE,
  RENV_PATHS_RENV = file.path("utils/renv"),
  RENV_PATHS_LOCKFILE = file.path("utils/proj_settings/renv.lock"),
  
  ## Renv settings
  RENV_INSTALL_STAGED = "FALSE",
  
  # Performance
  RENV_CONFIG_PAK_ENABLED = FALSE, # Pak gives error with solving dependencies, so disabled
  RENV_CONFIG_INSTALL_JOBS = 4, # Pak does parallelization by default, so not needed
  
  # Specfic settings, renv is within setup scripts checked and synchronized if needed
  RENV_CONFIG_SYNCHRONIZED_CHECK = FALSE,
  
  # Ensure renv uses local library instead of cache (needed because renv::init() isn't run)
  RENV_PATHS_LIBRARY = file.path("utils/renv/library")
)

# More renv options
options(pkg.install.staged.warn = FALSE)
options(pkgType = "binary")
options(renv.config.install.binary = TRUE)

source("utils/renv/activate.R")

