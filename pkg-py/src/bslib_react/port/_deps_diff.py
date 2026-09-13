"""Compare what the browser loads for a parent app and its port.

Ported from ``tools/port/deps-diff.R``: starts (or attaches to) both apps,
fetches the page each one serves, and compares every stylesheet and script
in the served page plus the inline styles in ``<head>``. Standard library
only: :mod:`urllib.request` for the GET requests, :mod:`html.parser` to pull
``<link>``/``<script>``/``<style>`` out of the response, :mod:`hashlib` for
byte comparison of fetched assets.

Four kinds of difference are reported:

- files only the parent loads (the port sampler misses a widget)
- files only the port loads (for example bslib-react's own bundle)
- the same library under a different file name (a theme compile on one
  side, the stock file on the other, or a version bump)
- the same file name with different bytes (two theme compiles that differ)

Files that belong to bslib-react or shinyreact themselves are expected on
the port only and are marked, not counted.
"""

from __future__ import annotations

import hashlib
import re
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from typing import NamedTuple

from ._app import AppHandle, attach_app, start_app

# `ui.js` / `ui.css` are the shinyreact client entry point; `shinyreact*` and
# `bslib-react*` name the vendored bundles. All are expected on the port
# only -- a plain bslib/shiny parent never loads them.
_EXPECTED_PORT_ONLY_RE = re.compile(
    r"(^|/)ui\.(js|css)$|shinyreact|bslib-react", re.IGNORECASE
)

# DT's extensions (Buttons, and dt-core alongside them) only reach the
# parent's page once `renderDT()` actually runs, over the websocket -- the
# port's static sampler puts them in the head instead. Kept for parity with
# the R tool even though a Python port rarely compares against a DT parent.
_RENDER_TIME_ON_PARENT_RE = re.compile(r"^dt-(core|ext-)")


def expected(href: str) -> bool:
    """Whether ``href`` is expected to appear on the port side only."""
    return bool(_EXPECTED_PORT_ONLY_RE.search(href))


def _is_remote(href: str) -> bool:
    return bool(re.match(r"^https?://|^//", href))


def _clean(href: str) -> str:
    href = re.sub(r"^\.?/", "", href)
    return re.sub(r"[?#].*$", "", href)


def lib_key(href: str) -> str:
    """The library a file belongs to, so a version bump still pairs up.

    ``bootstrap-5.3.3/bootstrap.min.css`` and
    ``bootstrap-3.4.1/css/bootstrap.min.css`` both become ``"bootstrap"``;
    ``shared/ionrangeslider/css/ion.rangeSlider.css`` pairs with
    ``ionRangeSlider-2.3.1/ionRangeSlider.min.css``.
    """
    h = re.sub(r"^(https?:)?//[^/]+/", "", href)
    segments = [s for s in h.split("/") if s]
    key = (
        segments[1]
        if len(segments) >= 2 and segments[0] == "shared"
        else (segments[0] if segments else h)
    )
    key = key.lower()
    key = re.sub(r"\.(min\.)?(css|js)$", "", key)
    key = re.sub(r"[-_]?v?[0-9][0-9.]*$", "", key)
    return key


def _ext_of(href: str) -> str:
    return re.sub(r"[?#].*$", "", href).rsplit(".", 1)[-1].lower()


class _PageAssets(NamedTuple):
    css: list[str]
    js: list[str]
    inline_css: list[str]


class _PageAssetsParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.css: list[str] = []
        self.js: list[str] = []
        self.inline_css: list[str] = []
        self._in_head = False
        self._in_style = False

    def handle_starttag(self, tag: str, attrs) -> None:
        attrs_d = dict(attrs)
        href = attrs_d.get("href")
        src = attrs_d.get("src")
        if tag == "head":
            self._in_head = True
        elif tag == "link" and attrs_d.get("rel") == "stylesheet" and href:
            self.css.append(_clean(href))
        elif tag == "script" and src:
            self.js.append(_clean(src))
        elif tag == "style" and self._in_head:
            self._in_style = True
            self.inline_css.append("")

    def handle_startendtag(self, tag: str, attrs) -> None:
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag: str) -> None:
        if tag == "head":
            self._in_head = False
        elif tag == "style":
            self._in_style = False

    def handle_data(self, data: str) -> None:
        if self._in_style:
            self.inline_css[-1] += data


def _read_page(app: AppHandle) -> _PageAssets:
    with urllib.request.urlopen(app.url, timeout=20) as resp:
        html_text = resp.read().decode("utf-8", errors="replace")
    parser = _PageAssetsParser()
    parser.feed(html_text)
    squash = lambda s: re.sub(r"\s+", " ", s).strip()  # noqa: E731
    return _PageAssets(
        css=parser.css, js=parser.js, inline_css=[squash(s) for s in parser.inline_css]
    )


def _fetch_asset(app: AppHandle, href: str) -> tuple[str | None, int]:
    try:
        with urllib.request.urlopen(
            app.url.rstrip("/") + "/" + href.lstrip("/"), timeout=20
        ) as resp:
            data = resp.read()
    except (urllib.error.URLError, ConnectionError, TimeoutError, OSError):
        return None, 0
    return hashlib.md5(data).hexdigest(), len(data)  # noqa: S324 (identity check, not security)


@dataclass
class _KindDiff:
    kind: str
    only_parent: list[str] = field(default_factory=list)
    only_port: list[str] = field(default_factory=list)
    pairs: list[tuple[str, str]] = field(default_factory=list)
    changed: list[str] = field(default_factory=list)
    common_count: int = 0


def _diff_list(
    a: list[str], b: list[str]
) -> tuple[list[str], list[str], list[str], list[tuple[str, str]]]:
    """Split two ordered lists into common, only-a, only-b, and library-renamed pairs.

    A pair is an only-a item and an only-b item that share a
    :func:`lib_key` and extension -- the same library shipped under a
    different file name on each side (a theme compile vs. the stock file,
    or a version bump).
    """
    common = [x for x in a if x in b]
    only_a = [x for x in a if x not in b]
    only_b = [x for x in b if x not in a]

    pairs: list[tuple[str, str]] = []
    remaining_b = list(only_b)
    still_only_a: list[str] = []
    for x in only_a:
        key = (lib_key(x), _ext_of(x))
        candidates = [y for y in remaining_b if (lib_key(y), _ext_of(y)) == key]
        if len(candidates) == 1:
            pairs.append((x, candidates[0]))
            remaining_b.remove(candidates[0])
        else:
            still_only_a.append(x)
    return common, still_only_a, remaining_b, pairs


@dataclass
class DepsDiff:
    """The result of :func:`deps_diff`. ``.n`` is the unexpected-difference count."""

    n: int
    common: list[str]
    only_parent: list[str]
    only_port: list[str]
    changed: list[str]
    sections: list[_KindDiff] = field(default_factory=list)
    inline_only_parent: list[str] = field(default_factory=list)
    inline_only_port: list[str] = field(default_factory=list)
    inline_common_count: int = 0

    def __str__(self) -> str:
        lines: list[str] = []
        for section in self.sections:
            lines.append(f"\n## {section.kind}")
            if section.only_parent:
                lines.append("\nOnly the parent loads:")
                for h in section.only_parent:
                    lines.append(f"- {h}")
                    lines.append(
                        "    The port never renders this. Add it to page_deps."
                    )
            if section.only_port:
                lines.append("\nOnly the port loads:")
                for h in section.only_port:
                    if expected(h):
                        lines.append(f"- {h}  [expected: bslib-react/shinyreact]")
                    elif _RENDER_TIME_ON_PARENT_RE.match(h):
                        lines.append(
                            f"- {h}  [the parent loads this when the widget renders]"
                        )
                    else:
                        lines.append(f"- {h}")
                        lines.append(
                            "    The port renders something the parent does not."
                        )
            if section.pairs:
                lines.append("\nSame library, different file:")
                for p_href, q_href in section.pairs:
                    lines.append(f"- parent: {p_href}")
                    lines.append(f"  port:   {q_href}")
            if section.changed:
                lines.append("\nBoth load, different bytes:")
                for h in section.changed:
                    lines.append(f"- {h}")
            if (
                not section.only_parent
                and not section.only_port
                and not section.pairs
                and not section.changed
            ):
                lines.append(f"- same set on both sides ({section.common_count} files)")

        lines.append("\n## Inline head styles")
        if not self.inline_only_parent and not self.inline_only_port:
            lines.append(f"- same on both sides ({self.inline_common_count} blocks)")
        for s in self.inline_only_parent:
            lines.append(f"- only the parent: {s[:100]}")
        for s in self.inline_only_port:
            lines.append(f"- only the port: {s[:100]}")

        lines.append("")
        if self.n == 0:
            lines.append("RESULT: clean. The port loads what the parent loads.")
        else:
            lines.append(f"RESULT: {self.n} difference(s) to look at.")
        return "\n".join(lines)


def _require(value: str | Path | None, label: str) -> str | Path:
    if value is None:
        raise ValueError(
            f"deps_diff(): pass either `{label}` (a directory) or `{label}_url`"
        )
    return value


def deps_diff(
    parent: str | Path | None = None,
    port: str | Path | None = None,
    *,
    parent_url: str | None = None,
    port_url: str | None = None,
    timeout: float = 120,
    verbose: bool = False,
) -> DepsDiff:
    """Diff the dependencies a parent app and a port load in the browser.

    Args:
        parent: The parent app's directory. Omit if ``parent_url`` is given.
        port: The port's directory. Omit if ``port_url`` is given.
        parent_url: Attach to an already-running parent instead of starting one.
        port_url: Attach to an already-running port instead of starting one.
        timeout: Seconds to wait for a started app to answer.
        verbose: Currently unused by the returned report itself; reserved
            for callers (e.g. the CLI) that want to print the full asset
            lists in load order alongside the diff.

    Returns:
        A :class:`DepsDiff`. ``.n == 0`` means the port loads exactly what
        the parent loads (up to bslib-react's own expected extra files).
    """
    started: list[AppHandle] = []
    try:
        parent_app = (
            attach_app(parent_url, "parent")
            if parent_url
            else start_app(_require(parent, "parent"), timeout)
        )
        if not parent_url:
            started.append(parent_app)
        port_app = (
            attach_app(port_url, "port")
            if port_url
            else start_app(_require(port, "port"), timeout)
        )
        if not port_url:
            started.append(port_app)

        p = _read_page(parent_app)
        q = _read_page(port_app)

        n = 0
        sections: list[_KindDiff] = []
        common_all: list[str] = []
        only_parent_all: list[str] = []
        only_port_all: list[str] = []
        changed_all: list[str] = []

        for kind, a, b in (("Stylesheets", p.css, q.css), ("Scripts", p.js, q.js)):
            common, only_a, only_b, pairs = _diff_list(a, b)

            n += len(only_a)
            unexpected_only_b = [
                h
                for h in only_b
                if not expected(h) and not _RENDER_TIME_ON_PARENT_RE.match(h)
            ]
            n += len(unexpected_only_b)
            n += len(pairs)

            changed: list[str] = []
            for h in common:
                if _is_remote(h):
                    continue
                a_hash, a_size = _fetch_asset(parent_app, h)
                b_hash, b_size = _fetch_asset(port_app, h)
                if a_hash == b_hash:
                    continue
                n += 1
                changed.append(f"{h}  (parent {a_size}B, port {b_size}B)")

            sections.append(
                _KindDiff(
                    kind=kind,
                    only_parent=only_a,
                    only_port=only_b,
                    pairs=pairs,
                    changed=changed,
                    common_count=len(common),
                )
            )
            common_all.extend(common)
            only_parent_all.extend(only_a)
            only_port_all.extend(only_b)
            changed_all.extend(changed)

        inline_only_parent = [s for s in p.inline_css if s not in q.inline_css]
        inline_only_port = [s for s in q.inline_css if s not in p.inline_css]
        inline_common = len(p.inline_css) - len(inline_only_parent)
        n += len(inline_only_parent) + len(inline_only_port)

        return DepsDiff(
            n=n,
            common=common_all,
            only_parent=only_parent_all,
            only_port=only_port_all,
            changed=changed_all,
            sections=sections,
            inline_only_parent=inline_only_parent,
            inline_only_port=inline_only_port,
            inline_common_count=inline_common,
        )
    finally:
        for handle in started:
            handle.stop()
