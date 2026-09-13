"""Tests that the app starts cleanly and serves the expected client bundles.

The client's own markup is bslib-react's responsibility (see
pkg-js/tests/markup.test.tsx), and the bind mechanics are
pkg-js/tests/bind.test.tsx's job. py-shiny has no direct in-process
equivalent of R's shiny::testServer() for a plain function-based server, so
this drives a real subprocess the same way bslib_react.port.start_app()
does, the same tool a porter uses to check a live app.
"""

import urllib.request
from pathlib import Path

import pytest

from bslib_react.port import start_app

APP_DIR = Path(__file__).parent.parent


@pytest.fixture
def app_process():
    handle = start_app(APP_DIR, timeout=60)
    yield handle
    handle.stop()


def test_the_app_starts_with_no_server_errors(app_process):
    assert app_process.log_errors() == []


def test_the_served_page_loads_the_expected_bundles(app_process):
    with urllib.request.urlopen(app_process.url, timeout=10) as response:
        html = response.read().decode()
        status = response.status
    assert status == 200
    assert "ui.js" in html
    assert "bslib-react.js" in html
    assert "shinyreact" in html
