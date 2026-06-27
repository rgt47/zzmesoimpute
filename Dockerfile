# syntax=docker/dockerfile:1.4
# zzcollab Dockerfile v2.4.0

ARG BASE_IMAGE=rocker/r-ver
ARG R_VERSION=4.5.2
ARG USERNAME=analyst

FROM rocker/r-ver:4.5.2

# OCI image labels for reproducibility provenance and tooling integration.
# base_digest records the resolved sha256 of the rocker base at build time;
# ppm_snapshot records the dated PPM URL used to pin package binaries.
LABEL org.opencontainers.image.created="2026-06-25T23:26:02Z" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      zzcollab.template.version="2.4.0" \
      zzcollab.r.version="4.5.2" \
      zzcollab.base.image="rocker/r-ver:4.5.2" \
      zzcollab.base.digest="unknown" \
      zzcollab.ppm.snapshot="2026-06-25"

ARG USERNAME=analyst
ARG DEBIAN_FRONTEND=noninteractive

# RENV_PATHS_LIBRARY is outside the project bind-mount so the baked library
# is not shadowed at runtime. ZZCOLLAB_AUTO_RESTORE=false disables the
# startup restore so the image library is authoritative.
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 TZ=UTC \
    RENV_PATHS_LIBRARY=/opt/renv/library \
    RENV_PATHS_CACHE=/opt/renv/cache \
    RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/noble/2026-06-25" \
    ZZCOLLAB_CONTAINER=true \
    ZZCOLLAB_AUTO_RESTORE=false

# No additional system dependencies required

# Configure R to use Posit Package Manager for pre-compiled binaries
RUN echo 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/2026-06-25"))' \
        >> /usr/local/lib/R/etc/Rprofile.site && \
    echo 'options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))' \
        >> /usr/local/lib/R/etc/Rprofile.site

# Install pandoc for document rendering
RUN apt-get update && apt-get install -y --no-install-recommends pandoc && rm -rf /var/lib/apt/lists/*

# Install languageserver for IDE support and yaml for R Markdown dependencies
RUN R -e "install.packages(c('languageserver', 'yaml'))"

# Install renv and restore packages from lockfile (using PPM binaries).
# tools_install runs BEFORE renv::init so IDE tools (languageserver, yaml)
# are installed into the system library. renv::init creates /.Rprofile which
# activates renv for all subsequent R processes; any install.packages call
# after that step is intercepted by renv and installed to RENV_PATHS_LIBRARY,
# which can cause load-test failures for packages with native dependencies.
RUN R -e "install.packages('renv')"
RUN mkdir -p /opt/renv/library /opt/renv/cache && chmod 755 /opt/renv/library /opt/renv/cache
COPY renv.lock renv.lock
# renv::init creates the platform-specific library directory structure that
# renv::restore() requires to link packages from the cache. Without init,
# restore downloads to the cache but never populates the library.
RUN R -e "renv::init(bare=TRUE, force=TRUE, restart=FALSE); renv::restore()"

# Install zzrenvcheck as a validation tool (system library, outside project renv).
# Tag is pinned at scaffold time; bump ZZRENVCHECK_TAG in lib/constants.sh to upgrade.
# Runs after renv::init; remotes::install_github bypasses renv interception.
RUN R -e "install.packages('remotes')" && \
    R -e "remotes::install_github('rgt47/zzrenvcheck@v0.3.0')"

# Create non-root user
RUN useradd --create-home --shell /bin/bash ${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /usr/local/lib/R/site-library

USER ${USERNAME}
WORKDIR /home/${USERNAME}/project

CMD ["R", "--quiet"]
