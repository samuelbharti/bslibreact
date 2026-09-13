"""End-to-end smoke test for the scaffolded app.

Needs a browser (the `peek`/`tests-e2e` extras) and a built client bundle
(`npm install && npm run build` in this app's directory first), so it lives
under `tests/playwright/` -- excluded from the default `pytest` run by this
repo's `addopts`, the same way bslib-react's own playwright tests are.
"""

from playwright.sync_api import Page
from shiny.pytest import create_app_fixture
from shiny.run import ShinyAppProc

# Resolved relative to this test file's directory, per create_app_fixture()'s
# own convention -- two levels up is the app's root, where app.py lives.
app = create_app_fixture("../../app.py")


def test_app_answers(page: Page, app: ShinyAppProc) -> None:
    page.goto(app.url)
    assert page.title() != ""
