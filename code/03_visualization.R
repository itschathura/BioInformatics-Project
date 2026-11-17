# ==============================================================================
# NeuroWrite AI: Stage 03 - Neurophysiological & Performance Visualizations
# ==============================================================================
# Generates publication-ready figures saved to reports/figures/:
# 1. Neural Firing Rate Heatmap across top electrode channels and characters
# 2. 2D PCA Projection of handwritten character neural clusters (neural manifold)
# 3. Feature Importance plot (discriminative electrode ranking)
# 4. Confusion Matrix plot with classification performance overlay
# 5. Channel Dynamics Distribution across character classes
# ==============================================================================

cat("\n>>> [Stage 03] Generating NeuroWrite AI Visualizations...\n")

# Ensure output directory exists
fig_dir <- file.path("reports", "figures")
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# Load Processed Data and Metrics
# ------------------------------------------------------------------------------
data_path <- file.path("data", "processed", "bci_features.csv")
metrics_path <- file.path("models", "metrics.rds")

if (!file.exists(data_path) || !file.exists(metrics_path)) {
  stop("Prerequisite data or model metrics missing. Run Stages 01 and 02 first.")
}

bci_data <- read.csv(data_path, stringsAsFactors = TRUE)
metrics  <- readRDS(metrics_path)

has_ggplot2 <- requireNamespace("ggplot2", quietly = TRUE)
pal <- c("#2b5c8f", "#d95f02", "#7570b3", "#e7298a", "#1b9e77")
names(pal) <- levels(bci_data$target_char)

# ------------------------------------------------------------------------------
# Figure 1: Neural Firing Rate Heatmap Across Top Electrodes
# ------------------------------------------------------------------------------
cat("Generating Figure 1: Neural Firing Rate Heatmap...\n")
fig1_path <- file.path(fig_dir, "01_neural_firing_heatmap.png")

# Calculate mean firing rate per character for top 20 channels
top_channels <- sprintf("Ch_%02d", 1:20)
heat_data <- aggregate(bci_data[, top_channels], by = list(Character = bci_data$target_char), FUN = mean)
heat_matrix <- as.matrix(heat_data[, -1])
rownames(heat_matrix) <- paste("Letter", heat_data$Character)

png(fig1_path, width = 2800, height = 1800, res = 300)
par(mar = c(5, 7, 4, 6), bg = "#ffffff")
color_palette <- colorRampPalette(c("#f7fbff", "#6baed6", "#08519c", "#08306b"))(100)

image(1:ncol(heat_matrix), 1:nrow(heat_matrix), t(heat_matrix),
      col = color_palette, axes = FALSE,
      xlab = "Electrode Channel", ylab = "",
      main = "Intracortical Firing Rate Heatmap Across Attempted Characters (Hz)")
axis(1, at = 1:ncol(heat_matrix), labels = top_channels, las = 2, cex.axis = 0.85)
axis(2, at = 1:nrow(heat_matrix), labels = rownames(heat_matrix), las = 1, cex.axis = 1.0, font = 2)
box(col = "#333333")

# Annotate values inside cells
for (x in 1:ncol(heat_matrix)) {
  for (y in 1:nrow(heat_matrix)) {
    val <- round(heat_matrix[y, x], 1)
    col_text <- if (val > mean(heat_matrix)) "#ffffff" else "#111111"
    text(x, y, labels = val, col = col_text, cex = 0.75, font = 2)
  }
}

# Color key
usr <- par("usr")
key_y <- seq(usr[3], usr[4], length.out = 100)
key_x <- usr[2] + 0.35 * (usr[2] - usr[1])
par(xpd = TRUE)
for (k in 1:99) {
  rect(usr[2] + 0.03 * (usr[2] - usr[1]), key_y[k], usr[2] + 0.07 * (usr[2] - usr[1]), key_y[k+1],
       col = color_palette[k], border = NA)
}
rect(usr[2] + 0.03 * (usr[2] - usr[1]), usr[3], usr[2] + 0.07 * (usr[2] - usr[1]), usr[4], border = "#333333")
text(usr[2] + 0.05 * (usr[2] - usr[1]), usr[4] + 0.06 * (usr[4] - usr[3]), "Hz", font = 2, cex = 0.8)
text(usr[2] + 0.11 * (usr[2] - usr[1]), usr[3], sprintf("%.1f", min(heat_matrix)), cex = 0.75)
text(usr[2] + 0.11 * (usr[2] - usr[1]), usr[4], sprintf("%.1f", max(heat_matrix)), cex = 0.75)
par(xpd = FALSE)
dev.off()
cat(sprintf(" -> Saved: %s\n", fig1_path))

# ------------------------------------------------------------------------------
# Figure 2: 2D PCA Neural Cluster Projection
# ------------------------------------------------------------------------------
cat("Generating Figure 2: 2D PCA Cluster Projection...\n")
fig2_path <- file.path(fig_dir, "02_pca_cluster_projection.png")

pca_coords <- as.data.frame(metrics$pca$x[, 1:2])
pca_coords$target_char <- bci_data$target_char
pc1_var <- metrics$pca_summary$Variance_Prop[1]
pc2_var <- metrics$pca_summary$Variance_Prop[2]

png(fig2_path, width = 2800, height = 2000, res = 300)
par(mar = c(5, 5, 4, 8), bg = "#ffffff")
chars <- levels(pca_coords$target_char)
colors_map <- pal[as.character(pca_coords$target_char)]
pchs_map <- c(16, 17, 15, 18, 8)[as.integer(pca_coords$target_char)]

plot(pca_coords$PC1, pca_coords$PC2,
     col = colors_map, pch = pchs_map, cex = 1.3,
     xlab = sprintf("Principal Component 1 (%.2f%% Variance Explained)", pc1_var),
     ylab = sprintf("Principal Component 2 (%.2f%% Variance Explained)", pc2_var),
     main = "Neural Manifold: 2D PCA Projection of BCI Handwriting States",
     panel.first = {
       grid(col = "#e0e0e0", lty = 1)
       abline(h = 0, v = 0, col = "#b0b0b0", lty = 2)
     })

# Add cluster ellipses / centroids
for (cls in chars) {
  sub_pts <- pca_coords[pca_coords$target_char == cls, c("PC1", "PC2")]
  centroid <- colMeans(sub_pts)
  points(centroid[1], centroid[2], pch = 21, bg = pal[cls], col = "#000000", cex = 2.4, lwd = 2)
  text(centroid[1], centroid[2], labels = cls, col = "#ffffff", font = 2, cex = 1.0)
  
  # Convex hull boundary
  h <- chull(sub_pts)
  polygon(sub_pts[h, ], border = pal[cls], col = adjustcolor(pal[cls], alpha.f = 0.12), lwd = 1.8)
}

par(xpd = TRUE)
legend("topright", inset = c(-0.25, 0), legend = paste("Char '", chars, "'", sep = ""),
       col = pal[chars], pch = c(16, 17, 15, 18, 8), pt.cex = 1.4, bty = "n",
       title = "Target Character", title.font = 2)
par(xpd = FALSE)
dev.off()
cat(sprintf(" -> Saved: %s\n", fig2_path))

# ------------------------------------------------------------------------------
# Figure 3: Feature Importance (Top Neural Electrodes)
# ------------------------------------------------------------------------------
cat("Generating Figure 3: Feature Importance Plot...\n")
fig3_path <- file.path(fig_dir, "03_feature_importance.png")

top_imp <- head(metrics$var_importance, 15)
top_imp <- top_imp[order(top_imp$Importance), ] # ascending for horizontal barplot

png(fig3_path, width = 2800, height = 2000, res = 300)
par(mar = c(5, 7, 4, 3), bg = "#ffffff")
bp <- barplot(top_imp$Importance, names.arg = top_imp$Feature, horiz = TRUE, las = 1,
              col = "#2b5c8f", border = "#1a3b5c",
              xlab = "Relative Importance Score (Gini / F-Statistic)",
              main = "Top 15 Most Discriminative Neural Features in BCI Decoding",
              xlim = c(0, max(top_imp$Importance) * 1.15))
grid(nx = NULL, ny = NA, col = "#e0e0e0", lty = 1)
text(top_imp$Importance + max(top_imp$Importance) * 0.02, bp,
     labels = round(top_imp$Importance, 1), pos = 4, cex = 0.85, font = 2, col = "#333333")
dev.off()
cat(sprintf(" -> Saved: %s\n", fig3_path))

# ------------------------------------------------------------------------------
# Figure 4: Confusion Matrix Plot
# ------------------------------------------------------------------------------
cat("Generating Figure 4: Confusion Matrix Heatmap...\n")
fig4_path <- file.path(fig_dir, "04_confusion_matrix.png")

cm_table <- metrics$confusion_matrix
cm_prop <- prop.table(cm_table, margin = 2) * 100 # column percentages

png(fig4_path, width = 2600, height = 2200, res = 300)
par(mar = c(6, 6, 4, 4), bg = "#ffffff")
cm_colors <- colorRampPalette(c("#ffffff", "#deebf7", "#3182bd", "#08519c"))(100)

image(1:ncol(cm_table), 1:nrow(cm_table), t(cm_prop[nrow(cm_table):1, ]),
      col = cm_colors, axes = FALSE,
      xlab = "Actual Handwritten Character",
      ylab = "Decoded (Predicted) Character",
      main = sprintf("BCI Decoder Confusion Matrix (Test Accuracy: %.1f%%, Kappa: %.3f)",
                     metrics$overall_accuracy * 100, metrics$kappa))

axis(1, at = 1:ncol(cm_table), labels = colnames(cm_table), font = 2, cex.axis = 1.1)
axis(2, at = 1:nrow(cm_table), labels = rev(rownames(cm_table)), font = 2, cex.axis = 1.1, las = 1)
box(col = "#333333")

# Annotate counts and percentages
for (x in 1:ncol(cm_table)) {
  for (y in 1:nrow(cm_table)) {
    orig_y <- nrow(cm_table) - y + 1
    cnt <- cm_table[orig_y, x]
    pct <- round(cm_prop[orig_y, x], 1)
    txt <- sprintf("%d\n(%.1f%%)", cnt, pct)
    col_text <- if (pct > 50) "#ffffff" else "#111111"
    text(x, y, labels = txt, col = col_text, font = 2, cex = 1.1)
  }
}
dev.off()
cat(sprintf(" -> Saved: %s\n", fig4_path))

# ------------------------------------------------------------------------------
# Figure 5: Channel Dynamics Distribution Across Character Classes
# ------------------------------------------------------------------------------
cat("Generating Figure 5: Channel Dynamics Distribution...\n")
fig5_path <- file.path(fig_dir, "05_channel_dynamics_distribution.png")

top_chan_name <- top_imp$Feature[nrow(top_imp)] # most important channel
if (!top_chan_name %in% colnames(bci_data)) top_chan_name <- "Ch_12"

png(fig5_path, width = 2800, height = 1800, res = 300)
par(mar = c(5, 5, 4, 2), bg = "#ffffff")
boxplot(bci_data[[top_chan_name]] ~ bci_data$target_char,
        col = pal[levels(bci_data$target_char)],
        border = "#222222",
        notch = TRUE,
        xlab = "Target Handwritten Character",
        ylab = sprintf("%s Spiking Rate (Hz)", top_chan_name),
        main = sprintf("Electrode Firing Rate Modulation Across Character Classes (%s)", top_chan_name),
        las = 1)
grid(col = "#e0e0e0", lty = 1)
dev.off()
cat(sprintf(" -> Saved: %s\n", fig5_path))

cat("\n[SUCCESS] All 5 publication-grade figures successfully generated in 'reports/figures/'.\n")
cat("------------------------------------------------------------------------------\n\n")
