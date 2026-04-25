FROM --platform=linux/amd64 rocker/shiny:4.4.1

# System dependencies for R packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libpng-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libtiff-dev \
    libpq-dev \
    pandoc \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-xetex \
    lmodern \
    && rm -rf /var/lib/apt/lists/*

# Install Quarto
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.42/quarto-1.6.42-linux-amd64.deb \
    && dpkg -i quarto-1.6.42-linux-amd64.deb \
    && rm quarto-1.6.42-linux-amd64.deb

WORKDIR /app

# Install R package dependencies first (for Docker layer caching)
COPY DESCRIPTION .
RUN Rscript -e ' \
  install.packages("remotes"); \
  remotes::install_deps(".", dependencies = TRUE) \
'

# Copy the full package and install it
COPY . .
RUN Rscript -e 'remotes::install_local(".", dependencies = FALSE)'

EXPOSE 3838

ENV NFWA_STORAGE_BACKEND=file

CMD ["Rscript", "-e", "nfwa::run_app(host = '0.0.0.0', port = 3838)"]
