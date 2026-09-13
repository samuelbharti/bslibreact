"""Look at a running port the way the browser sees it, next to its parent.

Ported from ``tools/port/peek.R``. Starts the port (and the parent, when
given) with :func:`bslib_react.port.start_app`, opens each in headless
Chromium via Playwright, waits for Shiny to connect and settle, then reads
back console errors, bound input/output counts, output errors shown on the
page, the ``<html>``/``<body>`` attributes, the stylesheets in load order,
and the computed style/box of any selectors passed in. Saves one screenshot
per app and, when both apps ran, reports where the two readouts differ.

Playwright is imported inside :func:`peek` itself, not at module import
time, so ``from bslib_react.port import triage`` (or ``deps_diff``) never
requires it -- only calling ``peek()`` does.
"""

from __future__ import annotations

import json
import re
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Sequence

from ._app import AppHandle, attach_app, start_app

if TYPE_CHECKING:
    from playwright.sync_api import Browser, Page

_READOUT_JS_PATH = Path(__file__).parent / "peek-readout.js"

# Matches R's `grepl("^\\[(log|info|debug)\\]", ...)`: the "noisy" console
# levels hidden unless `all_console=True`.
_NOISY_CONSOLE_RE = re.compile(r"^\[(log|info|debug)\]")


@dataclass
class _SideReadout:
    name: str
    url: str
    info: dict
    console: list[str]
    screenshot: Path
    log_errors: list[str] = field(default_factory=list)

    def format(self, side: str, *, all_console: bool) -> str:
        info = self.info
        lines = [
            f"\n# {side}: {self.name}  ({self.url})",
            f"- title: {info.get('title')}",
        ]
        connected = "connected" if info.get("connected") else "NOT connected"
        shiny = "loaded" if info.get("shiny") else "MISSING"
        busy = ", still busy" if info.get("busy") else ""
        lines.append(f"- Shiny: {shiny}, {connected}{busy}")
        lines.append(
            f"- bound: {info.get('boundInputs', 0)} inputs, "
            f"{info.get('boundOutputs', 0)} outputs"
        )
        errors = info.get("outputErrors") or []
        if errors:
            lines.append("- output errors on the page:")
            for e in errors:
                lines.append(f"    {e}")
        noisy = [m for m in self.console if _NOISY_CONSOLE_RE.match(m)]
        shown = (
            self.console if all_console else [m for m in self.console if m not in noisy]
        )
        lines.append(
            f"- console: {len(self.console)} message(s), "
            f"{len(self.console) - len(noisy)} error or warning"
        )
        for m in shown:
            lines.append(f"    {m}")
        if self.log_errors:
            lines.append(f"- app log: {len(self.log_errors)} error line(s)")
            for m in self.log_errors[:8]:
                lines.append(f"    {m}")
        lines.append(f"- html: {_fmt_attrs(info.get('html', {}))}")
        lines.append(f"- body: {_fmt_attrs(info.get('body', {}))}")
        stylesheets = info.get("stylesheets") or []
        lines.append(f"- stylesheets ({len(stylesheets)}):")
        for s in stylesheets:
            lines.append(f"    {s}")
        for p in info.get("picked") or []:
            if p.get("missing"):
                lines.append(f"- select {p['sel']}: MISSING")
                continue
            id_part = f" id={p['id']}" if p.get("id") else ""
            cls_part = f' class="{p["cls"]}"' if p.get("cls") else ""
            lines.append(f"- select {p['sel']}: <{p['tag']}{id_part}{cls_part}>")
            lines.append(
                f"    box x,y,w,h: {','.join(str(v) for v in p['box'])}  "
                f"text: {p['text']}"
            )
            style = p.get("style", {})
            lines.append("    " + "  ".join(f"{k}={v}" for k, v in style.items()))
        lines.append(f"- screenshot: {self.screenshot}")
        return "\n".join(lines)


def _fmt_attrs(attrs: dict) -> str:
    if not attrs:
        return "(none)"
    return " ".join(f'{k}="{v}"' for k, v in attrs.items())


def _diff_readouts(parent: _SideReadout, port: _SideReadout) -> list[str]:
    lines: list[str] = []
    pa, pb = parent.info, port.info
    if pa.get("connected") != pb.get("connected"):
        lines.append(
            f"Shiny connected: parent {pa.get('connected')}, port {pb.get('connected')}"
        )
    if pa.get("boundInputs") != pb.get("boundInputs"):
        lines.append(
            f"bound inputs: parent {pa.get('boundInputs')}, "
            f"port {pb.get('boundInputs')}"
        )
    if pa.get("boundOutputs") != pb.get("boundOutputs"):
        lines.append(
            f"bound outputs: parent {pa.get('boundOutputs')}, "
            f"port {pb.get('boundOutputs')}"
        )
    for key in set(pa.get("html", {})) | set(pb.get("html", {})):
        if pa.get("html", {}).get(key) != pb.get("html", {}).get(key):
            lines.append(
                f'html {key}: parent "{pa.get("html", {}).get(key)}", '
                f'port "{pb.get("html", {}).get(key)}"'
            )
    for key in set(pa.get("body", {})) | set(pb.get("body", {})):
        if pa.get("body", {}).get(key) != pb.get("body", {}).get(key):
            lines.append(
                f'body {key}: parent "{pa.get("body", {}).get(key)}", '
                f'port "{pb.get("body", {}).get(key)}"'
            )
    sa, sb = pa.get("stylesheets") or [], pb.get("stylesheets") or []
    for s in sa:
        if s not in sb:
            lines.append(f"stylesheet only on the parent: {s}")
    for s in sb:
        if s not in sa:
            lines.append(f"stylesheet only on the port: {s}")
    for pick_a, pick_b in zip(pa.get("picked") or [], pb.get("picked") or []):
        if pick_a.get("missing") or pick_b.get("missing"):
            if pick_a.get("missing") != pick_b.get("missing"):
                where = "the parent" if pick_a.get("missing") else "the port"
                lines.append(f"select {pick_a['sel']}: missing on {where}")
            continue
        if pick_a.get("box") != pick_b.get("box"):
            box_a = ",".join(map(str, pick_a["box"]))
            box_b = ",".join(map(str, pick_b["box"]))
            lines.append(f"select {pick_a['sel']} box: parent {box_a}, port {box_b}")
        for key, val in pick_a.get("style", {}).items():
            other = pick_b.get("style", {}).get(key)
            if val != other:
                lines.append(
                    f"select {pick_a['sel']} {key}: parent {val}, port {other}"
                )
    err_a = sum(1 for m in parent.console if not _NOISY_CONSOLE_RE.match(m))
    err_b = sum(1 for m in port.console if not _NOISY_CONSOLE_RE.match(m))
    if err_a != err_b:
        lines.append(f"console errors or warnings: parent {err_a}, port {err_b}")
    return lines


@dataclass
class PeekReport:
    """The result of :func:`peek`. ``str()`` gives a readable report."""

    port: _SideReadout
    parent: _SideReadout | None
    diff: list[str]
    all_console: bool = False

    def __str__(self) -> str:
        parts: list[str] = []
        if self.parent is not None:
            parts.append(self.parent.format("parent", all_console=self.all_console))
        parts.append(self.port.format("port", all_console=self.all_console))
        if self.parent is not None:
            parts.append("\n# Differences, parent vs port")
            if self.diff:
                parts.extend(f"- {d}" for d in self.diff)
            else:
                parts.append(
                    "- none in what peek reads. Compare the two screenshots by eye."
                )
        return "\n".join(parts)


def _readout_script(select: Sequence[str]) -> str:
    template = _READOUT_JS_PATH.read_text(encoding="utf-8")
    return template.replace("__SELECTOR_LIST_JSON__", json.dumps(list(select)))


def _settle(page: "Page", max_wait: float) -> None:
    ready_js = (
        "!!(window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected && "
        "Shiny.shinyapp.isConnected()) && "
        "!document.documentElement.classList.contains('shiny-busy')"
    )
    started = time.monotonic()
    while True:
        elapsed = time.monotonic() - started
        try:
            ready = bool(page.evaluate(ready_js))
        except Exception:
            ready = False
        if (ready and elapsed >= 2) or elapsed >= max_wait:
            break
        page.wait_for_timeout(500)
    page.wait_for_timeout(1000)


def _peek_one(
    browser: "Browser",
    app: AppHandle,
    side: str,
    *,
    select: Sequence[str],
    click: str | None,
    wait: float,
    out_dir: Path,
    width: int,
    height: int,
) -> _SideReadout:
    page = browser.new_page(viewport={"width": width, "height": height})
    console: list[str] = []
    page.on("console", lambda msg: console.append(f"[{msg.type}] {msg.text}"))
    page.on("pageerror", lambda exc: console.append(f"[exception] {exc}"))
    page.on(
        "requestfailed",
        lambda request: console.append(
            f"[requestfailed] {request.url} {request.failure}"
        ),
    )

    page.goto(app.url)
    _settle(page, wait)
    if click:
        try:
            page.click(click, timeout=2000)
        except Exception:
            console.append(f"[peek] --click found nothing for {click}")
        _settle(page, wait)

    info = json.loads(page.evaluate(_readout_script(select)))
    screenshot = out_dir / f"{app.name}-{side}.png"
    page.screenshot(path=str(screenshot))
    page.close()
    return _SideReadout(
        name=app.name,
        url=app.url,
        info=info,
        console=console,
        screenshot=screenshot,
        log_errors=app.log_errors(),
    )


def peek(
    port: str | Path,
    *,
    parent: str | Path | None = None,
    url: str | None = None,
    parent_url: str | None = None,
    select: Sequence[str] = (),
    click: str | None = None,
    wait: float = 15,
    out: str | Path | None = None,
    width: int = 1400,
    height: int = 900,
    all_console: bool = False,
    timeout: float = 120,
) -> PeekReport:
    """Open the port (and optionally its parent) in headless Chromium and read them.

    Args:
        port: The port app's directory. Ignored if ``url`` is given.
        parent: The parent app's directory, for a side-by-side comparison.
        url: Attach to an already-running port instead of starting one.
        parent_url: Attach to an already-running parent instead of starting one.
        select: CSS selectors to inspect (computed style, bounding box, text).
        click: A CSS selector to click once (a tab, a button) before reading out.
        wait: Seconds to wait for Shiny to connect and settle.
        out: Directory to save screenshots to. Defaults to a
            ``bslib_react-peek`` subdirectory of the system temp directory;
            pass ``"docs/local/peek"`` for a spot Git already
            ignores in this repo.
        width: Viewport width.
        height: Viewport height.
        all_console: Include ``log``/``info``/``debug`` console messages in
            the printed report (errors and warnings always show).
        timeout: Seconds to wait for a started app to answer over HTTP.

    Returns:
        A :class:`PeekReport`. ``print(report)`` gives the same four-part
        readout (parent, port, diff) as the R tool.
    """
    try:
        from playwright.sync_api import sync_playwright
    except ImportError as exc:
        raise ImportError(
            "peek() needs Playwright, which is not installed. Run "
            '`pip install "bslib-react[peek]"` (or `uv sync --extra peek`), '
            "then `playwright install chromium`."
        ) from exc

    # Matches R's default (a subdirectory of tempdir(), not tempdir() itself)
    # -- this is a package other projects install, so it must not spray
    # screenshot files into the bare system temp root by surprise.
    out_dir = (
        Path(out) if out is not None else Path(tempfile_dir()) / "bslib_react-peek"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    started: list[AppHandle] = []
    try:
        port_app = attach_app(url, "app") if url else start_app(port, timeout=timeout)
        if not url:
            started.append(port_app)

        parent_app: AppHandle | None = None
        if parent_url:
            parent_app = attach_app(parent_url, "app")
        elif parent is not None:
            parent_app = start_app(parent, timeout=timeout)
            started.append(parent_app)
        if parent_app is not None and parent_app.name == port_app.name:
            parent_app.name = f"{port_app.name}-parent"

        with sync_playwright() as pw:
            browser = pw.chromium.launch(headless=True)
            try:
                parent_readout = None
                if parent_app is not None:
                    parent_readout = _peek_one(
                        browser,
                        parent_app,
                        "parent",
                        select=select,
                        click=click,
                        wait=wait,
                        out_dir=out_dir,
                        width=width,
                        height=height,
                    )
                port_readout = _peek_one(
                    browser,
                    port_app,
                    "port",
                    select=select,
                    click=click,
                    wait=wait,
                    out_dir=out_dir,
                    width=width,
                    height=height,
                )
            finally:
                browser.close()
    finally:
        for handle in started:
            handle.stop()

    diff = (
        _diff_readouts(parent_readout, port_readout)
        if parent_readout is not None
        else []
    )
    return PeekReport(
        port=port_readout, parent=parent_readout, diff=diff, all_console=all_console
    )


def tempfile_dir() -> str:
    """The system temp directory, as a function so it's easy to monkeypatch in tests."""
    import tempfile

    return tempfile.gettempdir()
