# ==============================================================================
# NeuroWrite AI: Package Installation and Environment Setup
# ==============================================================================
# This script inspects the local R library, identifies missing dependencies,
# and installs them from CRAN (https://cloud.r-project.org).
# Run via: Rscript setup_packages.R
# ==============================================================================

cat("\n==============================================================================\n")
cat("          NeuroWrite AI - Dependency Verification & Installation             \n")
cat("==============================================================================\n\n")

# Define target CRAN repository
cran_repo <- "https://cloud.r-project.org"

# Complete required tech stack
required_packages <- c(
  "tidyverse",    # Data manipulation & tidy grammar
  "R.matlab",     # Reader for MATLAB .mat files
  "caret",        # Classification and regression training framework
  "randomForest", # Random Forest ensemble classifier
  "e1071",        # Support Vector Machines and statistical functions
  "ggplot2",      # Data visualization grammar
  "plotly",       # Interactive web-based charting
  "shiny",        # Interactive web application framework
  "bslib",        # Modern Bootstrap 5 theming for Shiny
  "DT",           # Interactive JavaScript DataTables for R
  "rmarkdown",    # Dynamic reproducible reporting
  "knitr"         # Report engine for R Markdown
)

cat("Checking installed packages against required dependencies...\n")
installed_pkgs <- installed.packages()[, "Package"]

missing_pkgs <- setdiff(required_packages, installed_pkgs)

if (length(missing_pkgs) == 0) {
  cat("\n[OK] All required packages are already installed!\n")
} else {
  cat(sprintf("\nFound %d missing package(s): %s\n", length(missing_pkgs), paste(missing_pkgs, collapse = ", ")))
  cat("Initiating installation from CRAN:", cran_repo, "...\n\n")
  
  for (pkg in missing_pkgs) {
    cat(sprintf(" -> Installing '%s'...", pkg))
    tryCatch({
      install.packages(pkg, repos = cran_repo, dependencies = TRUE, quiet = TRUE)
      cat(" Done.\n")
    }, error = function(e) {
      cat(sprintf(" FAILED (%s)\n", e$message))
    })
  }
}

# Verification step
cat("\nVerifying package loadability:\n")
verification_status <- sapply(required_packages, function(pkg) {
  is_avail <- requireNamespace(pkg, quietly = TRUE)
  status_str <- if (is_avail) {
    ver <- as.character(packageVersion(pkg))
    sprintf("[OK] %-14s (v%s)", pkg, ver)
  } else {
    sprintf("[MISSING] %-14s (installation required)", pkg)
  }
  cat(status_str, "\n")
  is_avail
})

cat("\n------------------------------------------------------------------------------\n")
if (all(verification_status)) {
  cat("Environment Status: READY! All dependencies satisfied.\n")
  cat("You can now run: Rscript run_pipeline.R\n")
} else {
  cat("Environment Status: WARNING! Some dependencies could not be verified.\n")
  cat("Please ensure network access is enabled and re-run: Rscript setup_packages.R\n")
}
cat("==============================================================================\n\n")
