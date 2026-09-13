# Prepare data for a volcano plot from a differential expression results
# table. Pure logic, no shiny:: calls, so the same function backs both the
# R and the Python server (see volcano.py's volcano_data(), kept in step
# with this one).
#
# de_results: a data frame with at least gene, logFC, and the chosen p
# column. Returns columns: gene, logFC, p, neg_log10_p, status
# (Down/NS/Up), label.
volcano_data <- function(
  de_results,
  lfc_threshold = 1,
  p_threshold = 0.05,
  p_col = c("padj", "pvalue"),
  label_top_n = 10
) {
  p_col <- match.arg(p_col)
  required <- c("gene", "logFC", p_col)
  missing <- setdiff(required, names(de_results))
  if (length(missing) > 0) {
    stop("de_results is missing required column(s): ", toString(missing))
  }

  df <- data.frame(
    gene = as.character(de_results$gene),
    logFC = de_results$logFC,
    p = de_results[[p_col]],
    stringsAsFactors = FALSE
  )

  # Guard p == 0 (would be Inf after -log10) by flooring at the smallest
  # positive double.
  df$neg_log10_p <- -log10(pmax(df$p, .Machine$double.xmin))

  df$status <- de_status(df$logFC, df$p, lfc_threshold, p_threshold)

  # Label the most significant genes (by p), up to label_top_n.
  df$label <- NA_character_
  if (label_top_n > 0) {
    candidates <- which(df$status != "NS")
    if (length(candidates) > 0) {
      ordered <- candidates[order(df$p[candidates])]
      top <- utils::head(ordered, label_top_n)
      df$label[top] <- df$gene[top]
    }
  }

  df
}

# Counts per status, as a named integer vector (Down, NS, Up).
volcano_status_counts <- function(vdata) {
  table(factor(vdata$status, levels = c("Down", "NS", "Up")))
}

# Down/Up/NS classification, shared with the counts above so the plot and
# the value boxes always agree.
de_status <- function(logFC, p, lfc_threshold = 1, p_threshold = 0.05) {
  sig <- !is.na(p) & p < p_threshold
  status <- rep("NS", length(logFC))
  status[sig & logFC >= lfc_threshold] <- "Up"
  status[sig & logFC <= -lfc_threshold] <- "Down"
  factor(status, levels = c("Down", "NS", "Up"))
}
