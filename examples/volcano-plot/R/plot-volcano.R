# ggplot2 renderer for the volcano plot.
#
# xlab: x-axis title, a plotmath expression by default (the log2 fold
# change label); highlight: optional gene names to ring and bold-label,
# used for cross-highlighting from elsewhere in a larger app (unused by
# this standalone example, kept so the function matches volcano.py's
# plot_volcano() signature one for one).
plot_volcano <- function(
  vdata,
  lfc_threshold = 1,
  p_threshold = 0.05,
  xlab = expression(log[2] ~ fold ~ change),
  highlight = character(0)
) {
  p <- ggplot2::ggplot(
    vdata,
    ggplot2::aes(x = logFC, y = neg_log10_p, colour = status)
  ) +
    ggplot2::geom_point(alpha = 0.7, size = 1.6) +
    ggplot2::geom_vline(
      xintercept = c(-lfc_threshold, lfc_threshold),
      linetype = "dashed",
      colour = "grey50"
    ) +
    ggplot2::geom_hline(
      yintercept = -log10(p_threshold),
      linetype = "dashed",
      colour = "grey50"
    ) +
    ggplot2::scale_colour_manual(values = ltc_status_colours(), drop = FALSE) +
    ggplot2::labs(x = xlab, y = expression(-log[10] ~ p), colour = NULL) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(legend.position = "top")

  labelled <- vdata[!is.na(vdata$label), , drop = FALSE]
  if (nrow(labelled) > 0) {
    p <- p +
      ggrepel::geom_text_repel(
        data = labelled,
        ggplot2::aes(label = label),
        size = 3.5,
        max.overlaps = Inf,
        show.legend = FALSE,
        colour = "#404041"
      )
  }

  hl <- vdata[vdata$gene %in% highlight, , drop = FALSE]
  if (nrow(hl) > 0) {
    p <- p +
      ggplot2::geom_point(
        data = hl,
        shape = 21,
        size = 3.4,
        stroke = 1.2,
        colour = "#111111",
        fill = NA,
        show.legend = FALSE
      ) +
      ggrepel::geom_text_repel(
        data = hl,
        ggplot2::aes(label = gene),
        size = 4,
        fontface = "bold",
        max.overlaps = Inf,
        show.legend = FALSE,
        colour = "#111111"
      )
  }

  p
}
