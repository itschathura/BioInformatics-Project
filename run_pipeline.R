# NeuroWrite AI: End-to-End BCI Pipeline Orchestrator
# ==============================================================================
# Author: NeuroWrite AI Team
# Execution: Rscript run_pipeline.R
# Description:
#   Orchestrates data preprocessing, neural feature extraction, PCA dimensionality
#   reduction, Random Forest model training, and publication figure generation.
# ==============================================================================

start_time <- Sys.time()

cat("\n================================================================================\n")
cat("                       NEUROWRITE AI: BCI PIPELINE                              \n")
cat("      Intracortical Microelectrode Array Neural Handwriting Decoder             \n")
cat("================================================================================\n\n")

# Detect script directory (supports both code/ and R/ layouts)
script_dir <- if (dir.exists("code") && file.exists(file.path("code", "01_data_preprocessing.R"))) "code" else "R"

# Step 1: Preprocessing & Feature Extraction
t1 <- Sys.time()
cat("--------------------------------------------------------------------------------\n")
cat("[1/3] EXECUTING STAGE 01: DATA PREPROCESSING & FEATURE EXTRACTION\n")
cat("--------------------------------------------------------------------------------\n")
source(file.path(script_dir, "01_data_preprocessing.R"), local = FALSE)
cat(sprintf("Stage 01 completed in %.2f seconds.\n\n", as.numeric(difftime(Sys.time(), t1, units = "secs"))))

# Step 2: Model Training & Evaluation
t2 <- Sys.time()
cat("--------------------------------------------------------------------------------\n")
cat("[2/3] EXECUTING STAGE 02: PCA & MACHINE LEARNING DECODER TRAINING\n")
cat("--------------------------------------------------------------------------------\n")
source(file.path(script_dir, "02_model_training.R"), local = FALSE)
cat(sprintf("Stage 02 completed in %.2f seconds.\n\n", as.numeric(difftime(Sys.time(), t2, units = "secs"))))

# Step 3: Visualization & Figure Generation
t3 <- Sys.time()
cat("--------------------------------------------------------------------------------\n")
cat("[3/3] EXECUTING STAGE 03: NEUROPHYSIOLOGICAL VISUALIZATION\n")
cat("--------------------------------------------------------------------------------\n")
source(file.path(script_dir, "03_visualization.R"), local = FALSE)
cat(sprintf("Stage 03 completed in %.2f seconds.\n\n", as.numeric(difftime(Sys.time(), t3, units = "secs"))))

# Summary
total_elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat("================================================================================\n")
cat("                     PIPELINE EXECUTION COMPLETE!                               \n")
cat("================================================================================\n")
cat(sprintf("Total Pipeline Runtime:  %.2f seconds\n", total_elapsed))
cat("Generated Artifacts:\n")
cat("  - Processed Data:      data/processed/bci_features.csv\n")
cat("  - Trained Model:       models/rf_bci_model.rds\n")
cat("  - Evaluation Metrics:  models/metrics.rds\n")
cat("  - Figures Generated:   reports/figures/ (5 high-res PNG plots)\n\n")
