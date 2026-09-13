"""``host_input()``: mounting a server-rendered widget inside a React page."""

from __future__ import annotations

import re
import urllib.request
from pathlib import Path
from typing import Any

import pytest
from bslib_react._host import host_input
from htmltools import TagList
from shiny import ui


class _FakeOutputs:
    """Just enough of ``Outputs.__call__``'s protocol to unit-test ``host_input()``.

    Matches the real decorator's signature (``renderer=None, *, id=None,
    suspend_when_hidden=True, priority=0``) and records what was registered,
    without needing a live Shiny session -- ``host_input()`` never touches
    reactivity or the session itself, so a real session buys nothing here
    except the cost of a subprocess and a websocket handshake.
    """

    def __init__(self) -> None:
        # `id` is `str | None` in the real Outputs.__call__ signature (a
        # renderer falls back to its function's __name__ when None); this
        # test always passes an explicit id, but the type stays honest.
        self.registered: dict[str | None, dict[str, Any]] = {}

    def __call__(
        self,
        renderer: Any = None,
        *,
        id: str | None = None,
        suspend_when_hidden: bool = True,
        priority: int = 0,
    ) -> Any:
        def set_renderer(r: Any) -> Any:
            self.registered[id] = {
                "renderer": r,
                "suspend_when_hidden": suspend_when_hidden,
            }
            return r

        if renderer is not None:
            return set_renderer(renderer)
        return set_renderer


def _sync_value(renderer: Any) -> Any:
    """Call a ``@render.ui``-decorated function's original body directly.

    ``renderer.fn`` is an ``AsyncValueFn`` wrapping the function ``host_input()``
    defined; ``get_sync_fn()`` hands back that original (synchronous) function,
    which can be called with no session or reactive context at all since it
    does nothing session-dependent -- it just calls ``widget()`` and checks
    the result for an id collision.
    """
    return renderer.fn.get_sync_fn()()


def test_host_input_returns_the_output_name_and_registers_it() -> None:
    outputs = _FakeOutputs()
    name = host_input(
        outputs, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30)
    )
    assert name == "bins_ui"
    assert "bins_ui" in outputs.registered


def test_host_input_uses_a_custom_suffix() -> None:
    outputs = _FakeOutputs()
    name = host_input(
        outputs,
        "bins",
        lambda: ui.input_slider("bins", "Bins", 1, 50, 30),
        suffix="_widget",
    )
    assert name == "bins_widget"
    assert "bins_widget" in outputs.registered


def test_host_input_disables_suspend_when_hidden() -> None:
    """A React-mounted output has no server-rendered container Shiny's own

    visibility tracking can see, so it must never be suspended for looking
    hidden.
    """
    outputs = _FakeOutputs()
    host_input(outputs, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))
    assert outputs.registered["bins_ui"]["suspend_when_hidden"] is False


def test_host_input_renders_the_widget() -> None:
    outputs = _FakeOutputs()
    host_input(outputs, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))
    value = _sync_value(outputs.registered["bins_ui"]["renderer"])
    html = TagList(value).render()["html"]
    assert 'id="bins"' in html
    assert "js-range-slider" in html


def test_host_input_raises_on_id_collision() -> None:
    outputs = _FakeOutputs()
    # The widget's own id happens to equal the hosted output's name.
    host_input(outputs, "bins", lambda: ui.input_slider("bins_ui", "Bins", 1, 50, 30))
    with pytest.raises(ValueError, match="bins_ui"):
        _sync_value(outputs.registered["bins_ui"]["renderer"])


def test_host_input_collision_check_looks_inside_nested_tags() -> None:
    outputs = _FakeOutputs()

    def widget() -> Any:
        return ui.div(ui.div(ui.input_slider("bins_ui", "Bins", 1, 50, 30)))

    host_input(outputs, "bins", widget)
    with pytest.raises(ValueError, match="bins_ui"):
        _sync_value(outputs.registered["bins_ui"]["renderer"])


def test_host_input_in_a_real_running_app(tmp_path: Path) -> None:
    """Smoke test against a real app: the output exists and answers over HTTP.

    Confirms `host_input()`'s use of the *real* `output`/`render.ui`
    machinery works end to end (not just against the protocol
    `_FakeOutputs` assumes), by starting an actual Shiny process and
    checking the output placeholder it registers is present on the page --
    the same placeholder Shiny fills in dynamically over the websocket once
    a client connects, which a plain HTTP GET does not drive.
    """
    from bslib_react._app_runner import start_app

    app_dir = tmp_path / "hostapp"
    app_dir.mkdir()
    (app_dir / "app.py").write_text(
        "from shiny import App, ui\n"
        "from bslib_react import host_input\n\n"
        'app_ui = ui.page_fluid(ui.output_ui("bins_ui"))\n\n'
        "def server(input, output, session):\n"
        '    host_input(output, "bins", lambda: '
        'ui.input_slider("bins", "Bins", 1, 50, 30))\n\n'
        "app = App(app_ui, server)\n",
        encoding="utf-8",
    )

    handle = start_app(app_dir, timeout=60)
    try:
        with urllib.request.urlopen(handle.url, timeout=10) as resp:
            html = resp.read().decode("utf-8")
        assert re.search(
            r'id="bins_ui"[^>]*class="shiny-html-output"|class="shiny-html-output"[^>]*id="bins_ui"',
            html,
        )
    finally:
        handle.stop()
