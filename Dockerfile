FROM --platform=linux/amd64 rocker/shiny:4.4.1

# Switch apt to HTTPS and disable SSL verification (corporate proxy intercepts HTTP on port 80)
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list && \
    echo 'Acquire::https::Verify-Peer "false";' >> /etc/apt/apt.conf.d/99no-check-ssl

# System dependencies for R packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    pkg-config \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libtiff-dev \
    libpq-dev \
    libcairo2-dev \
    libxt-dev \
    zip \
    pandoc \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-xetex \
    lmodern \
    && rm -rf /var/lib/apt/lists/*

# Trust corporate SSL proxy (e.g. Zscaler) by disabling strict cert checks.
# ~/.curlrc covers the curl binary used by shell commands.
# Rprofile.site covers two separate R mechanisms:
#   - download.file.method/extra: controls download.file() (package tarballs)
#   - libcurlNoPeerVerify: controls url() connections (PACKAGES index fetch)
RUN echo "insecure" >> /root/.curlrc && \
    mkdir -p /etc/R && \
    printf 'options(\n  download.file.method = "wget",\n  download.file.extra = "--no-check-certificate",\n  libcurlNoPeerVerify = TRUE\n)\n' \
      >> /etc/R/Rprofile.site

# Install Quarto
RUN curl -k -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.42/quarto-1.6.42-linux-amd64.deb \
    && dpkg -i quarto-1.6.42-linux-amd64.deb \
    && rm quarto-1.6.42-linux-amd64.deb

WORKDIR /app

# Install R package dependencies first (for Docker layer caching)
# PPM binary repo: pre-compiled Ubuntu 22.04 (jammy) packages — much faster than source.
COPY DESCRIPTION .
RUN Rscript -e ' \
  options( \
    download.file.method = "wget", \
    download.file.extra = "--no-check-certificate", \
    libcurlNoPeerVerify = TRUE, \
    repos = c(CRAN = "https://p3m.dev/cran/__linux__/jammy/latest") \
  ); \
  install.packages("remotes"); \
  remotes::install_deps(".", dependencies = TRUE); \
  missing_pkgs <- c("gtsummary", "broom.helpers"); \
  to_install <- missing_pkgs[!vapply(missing_pkgs, requireNamespace, logical(1), quietly = TRUE)]; \
  if (length(to_install) > 0) install.packages(to_install, dependencies = TRUE); \
  cat("Done installing dependencies\n") \
'

# Verify all Imports are installed (fail fast if install_deps silently skipped any)
RUN Rscript -e ' \
  deps <- remotes::local_package_deps(".", dependencies = "Imports"); \
  missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]; \
  if (length(missing) > 0) stop("Missing packages: ", paste(missing, collapse = ", ")) \
'

# Copy the full package and install it
COPY . .
RUN R CMD INSTALL --no-multiarch --no-test-load . \
    && Rscript -e 'library(nfwa); cat("nfwa", as.character(packageVersion("nfwa")), "OK\n")'

EXPOSE 3838

ENV NFWA_STORAGE_BACKEND=file

CMD ["Rscript", "-e", "nfwa::run_app(host = '0.0.0.0', port = 3838)"]
