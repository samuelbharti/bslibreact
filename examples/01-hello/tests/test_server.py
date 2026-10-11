"""Tests that the app starts cleanly and serves the expected client bundles.

The client's own markup is bslib-react's responsibility (see
pkg-js/tests/markup.test.tsx), and the bind mechanics are
pkg-js/tests/bind.test.tsx's job. py-shiny has no in-process equivalent of
R's shiny::testServer() for a plain function-based server, so this starts
the real app with py-shiny's own runner.
"""

import urllib.request
from pathlib import Path

import pytest
from shiny.run import run_shiny_app

APP_DIR = Path(__file__).parent.parent


@pytest.fixture
def app_url():
    proc = run_shiny_app(APP_DIR / "app.py", cwd=str(APP_DIR), timeout_secs=60)
    yield proc.url
    proc.close()


def test_the_served_page_loads_the_expected_bundles(app_url):
    with urllib.request.urlopen(app_url, timeout=10) as response:
        html = response.read().decode()
        status = response.status
    assert status == 200
    assert "ui.js" in html
    assert "bslib-react.js" in html
    assert "shinyreact" in html
