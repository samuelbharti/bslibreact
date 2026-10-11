"""Tests the pure data layer (volcano.py) directly: no Shiny session
needed. The server wiring (app.py) is not tested here; see test_server.py
in examples/01-hello for that kind of check, and docs/porting.md for why a
component's own markup and bind mechanics belong to pkg-js, not to an
example app.
"""

import sys
from pathlib import Path

import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))
from volcano import volcano_data, volcano_status_counts  # noqa: E402

APP_DIR = Path(__file__).parent.parent


@pytest.fixture
def de_results() -> pd.DataFrame:
    return pd.read_csv(APP_DIR / "data" / "de_results.csv")


def test_volcano_data_classifies_status_from_logfc_and_p_together(de_results):
    vd = volcano_data(de_results, lfc_threshold=1, p_threshold=0.05, p_col="padj")
    assert set(vd["status"].cat.categories) == {"Down", "NS", "Up"}
    up = vd[(vd["logFC"] >= 1) & (vd["p"] < 0.05)]
    assert (up["status"] == "Up").all()
    down = vd[(vd["logFC"] <= -1) & (vd["p"] < 0.05)]
    assert (down["status"] == "Down").all()


def test_volcano_data_labels_at_most_label_top_n_genes_by_smallest_p(de_results):
    vd = volcano_data(de_results, label_top_n=5)
    labelled = vd[vd["label"].notna()]
    assert len(labelled) == 5
    assert (labelled["status"] != "NS").all()
    unlabelled_sig = vd[vd["label"].isna() & (vd["status"] != "NS")]
    assert labelled["p"].max() <= unlabelled_sig["p"].min()


def test_volcano_data_raises_clearly_on_a_missing_required_column(de_results):
    bad = de_results.drop(columns=["logFC"])
    with pytest.raises(ValueError, match="logFC"):
        volcano_data(bad)


def test_volcano_status_counts_always_reports_all_three_levels(de_results):
    vd = volcano_data(de_results, lfc_threshold=100)
    counts = volcano_status_counts(vd)
    assert set(counts.keys()) == {"Down", "NS", "Up"}
    assert counts["Up"] == 0
