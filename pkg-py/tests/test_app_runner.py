"""``port._app.start_app()``/``attach_app()``: start a Shiny app and wait for it."""

from __future__ import annotations

import shutil
import urllib.error
import urllib.request
from pathlib import Path

import pytest
from bslib_react.port import AppHandle, attach_app, start_app
from shiny.run import ShinyAppProc


def _answers_200(url: str) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return resp.status == 200
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
        return False


def test_start_and_stop_a_python_app(tmp_path: Path) -> None:
    app_dir = tmp_path / "hello"
    app_dir.mkdir()
    (app_dir / "app.py").write_text(
        "from shiny import App, ui\n\n"
        'app = App(ui.page_fluid("hi"), lambda input, output, session: None)\n',
        encoding="utf-8",
    )

    handle = start_app(app_dir, timeout=60)
    try:
        assert handle.url.startswith("http://127.0.0.1:")
        assert _answers_200(handle.url)
        proc = handle.proc
    finally:
        handle.stop()

    # A Python app's handle wraps shiny.run's own ShinyAppProc.
    assert isinstance(proc, ShinyAppProc)
    # `.stop()` sends the terminate signal; give the OS a moment to reap it
    # before asserting the subprocess is actually gone.
    proc.proc.wait(timeout=10)
    assert proc.proc.poll() is not None
    assert not _answers_200(handle.url)


def test_missing_app_directory_raises_clearly(tmp_path: Path) -> None:
    with pytest.raises(FileNotFoundError, match="not found"):
        start_app(tmp_path / "does-not-exist")


def test_directory_with_no_entry_file_raises_clearly(tmp_path: Path) -> None:
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    with pytest.raises(FileNotFoundError, match="app.py"):
        start_app(empty_dir)


def test_attach_app_requires_something_answering() -> None:
    with pytest.raises(RuntimeError, match="nothing answers"):
        attach_app("http://127.0.0.1:1/")  # port 1: nothing should ever be listening


def test_attach_app_to_a_running_app(tmp_path: Path) -> None:
    app_dir = tmp_path / "hello"
    app_dir.mkdir()
    (app_dir / "app.py").write_text(
        "from shiny import App, ui\n\n"
        'app = App(ui.page_fluid("hi"), lambda input, output, session: None)\n',
        encoding="utf-8",
    )
    handle = start_app(app_dir, timeout=60)
    try:
        attached = attach_app(handle.url, name="hello")
        assert attached.dir is None
        assert attached.proc is None
        assert _answers_200(attached.url)
    finally:
        handle.stop()


@pytest.mark.skipif(shutil.which("Rscript") is None, reason="Rscript not on PATH")
def test_start_and_stop_an_r_app(tmp_path: Path) -> None:
    app_dir = tmp_path / "hello_r"
    app_dir.mkdir()
    (app_dir / "app.R").write_text(
        "library(shiny)\n"
        'ui <- fluidPage("hi")\n'
        "server <- function(input, output, session) {}\n"
        "shinyApp(ui, server)\n",
        encoding="utf-8",
    )

    handle: AppHandle = start_app(app_dir, timeout=90)
    try:
        assert _answers_200(handle.url)
        assert handle.log is not None
    finally:
        handle.stop()
