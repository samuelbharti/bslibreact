"""Volcano plot data preparation and rendering.

The Python twin of R/_shared/volcano-data.R, R/_shared/palettes.R, and
R/plot-volcano.R. Kept as one file, since Python does not split a data
layer from a package-provided colour palette the way this example's R
side inherited from a larger app family; the docstrings below are the same
contract either language implements.
"""

from __future__ import annotations

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# The R side reads these three colours from an internal palette package
# not part of this repository; these are that package's documented
# fallback values, copied verbatim. Kept in step with palettes.R's
# ltc_status_colours().
STATUS_COLOURS = {"Down": "#3d5a80", "NS": "#B8BCC2", "Up": "#ee6c4d"}


def de_status(
    log_fc: pd.Series, p: pd.Series, lfc_threshold: float = 1, p_threshold: float = 0.05
) -> pd.Categorical:
    """Down/Up/NS classification, shared with the counts below so the plot
    and the value boxes always agree."""
    sig = p.notna() & (p < p_threshold)
    status = pd.Series("NS", index=log_fc.index)
    status[sig & (log_fc >= lfc_threshold)] = "Up"
    status[sig & (log_fc <= -lfc_threshold)] = "Down"
    return pd.Categorical(status, categories=["Down", "NS", "Up"])


def volcano_data(
    de_results: pd.DataFrame,
    lfc_threshold: float = 1,
    p_threshold: float = 0.05,
    p_col: str = "padj",
    label_top_n: int = 10,
) -> pd.DataFrame:
    """Prepare data for a volcano plot from a differential expression
    results table.

    de_results: a data frame with at least gene, logFC, and p_col.
    Returns columns: gene, logFC, p, neg_log10_p, status (Down/NS/Up), label.
    """
    required = {"gene", "logFC", p_col}
    missing = required - set(de_results.columns)
    if missing:
        raise ValueError(
            f"de_results is missing required column(s): {', '.join(sorted(missing))}"
        )

    df = pd.DataFrame(
        {
            "gene": de_results["gene"].astype(str),
            "logFC": de_results["logFC"],
            "p": de_results[p_col],
        }
    )

    # Guard p == 0 (would be inf after -log10) by flooring at the smallest
    # positive float, matching R's .Machine$double.xmin.
    df["neg_log10_p"] = -np.log10(df["p"].clip(lower=np.finfo(float).tiny))

    df["status"] = de_status(df["logFC"], df["p"], lfc_threshold, p_threshold)

    df["label"] = None
    if label_top_n > 0:
        candidates = df.index[df["status"] != "NS"]
        if len(candidates) > 0:
            ordered = df.loc[candidates, "p"].sort_values().index
            top = ordered[:label_top_n]
            df.loc[top, "label"] = df.loc[top, "gene"]

    return df


def volcano_status_counts(vdata: pd.DataFrame) -> dict[str, int]:
    """Counts per status, as a plain dict (Down, NS, Up)."""
    counts = vdata["status"].value_counts().reindex(["Down", "NS", "Up"], fill_value=0)
    return {status: int(counts.at[status]) for status in ("Down", "NS", "Up")}


def plot_volcano(
    vdata: pd.DataFrame,
    lfc_threshold: float = 1,
    p_threshold: float = 0.05,
    xlab: str = "log$_2$ fold change",
):
    """matplotlib renderer for the volcano plot.

    Labels use a plain offset annotation rather than a label-repulsion
    algorithm (R's ggrepel::geom_text_repel()): a deliberate simplification
    for this example, not a missing feature of bslibreact itself. Labels
    can overlap at high label_top_n values as a result.
    """
    fig, ax = plt.subplots(figsize=(9, 5.5))

    for status, colour in STATUS_COLOURS.items():
        rows = vdata[vdata["status"] == status]
        ax.scatter(
            rows["logFC"], rows["neg_log10_p"], c=colour, alpha=0.7, s=22, label=status
        )

    ax.axvline(-lfc_threshold, linestyle="--", color="grey", linewidth=1)
    ax.axvline(lfc_threshold, linestyle="--", color="grey", linewidth=1)
    ax.axhline(-np.log10(p_threshold), linestyle="--", color="grey", linewidth=1)

    labelled = vdata[vdata["label"].notna()]
    for _, row in labelled.iterrows():
        ax.annotate(
            row["label"],
            (row["logFC"], row["neg_log10_p"]),
            textcoords="offset points",
            xytext=(4, 4),
            fontsize=8.5,
            color="#404041",
        )

    ax.set_xlabel(xlab)
    ax.set_ylabel("-log$_{10}$ p")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, 1.12), ncol=3, frameon=False)
    fig.tight_layout()
    return fig
