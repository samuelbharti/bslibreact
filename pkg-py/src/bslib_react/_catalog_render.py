"""Render the markup catalog to the JSON file ``pkg-js``'s tests read.

Implements the Python side of ``docs/markup-catalog.md`` (schema 1). Read
that file first -- it is the contract this module's output must match,
field for field, with pkg-r's renderer.
"""

from __future__ import annotations

import importlib.metadata
import json
import platform
import shutil
import tempfile
import urllib.parse
import urllib.request
import warnings
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import TYPE_CHECKING, Literal, Sequence

from htmltools import TagList

from ._catalog import SAMPLES, Sample, catalog_eval, catalog_hash

if TYPE_CHECKING:
    from htmltools import TagChild
from ._version import __version__

ServedMode = Literal["auto", "never", "always"]

# The throwaway app `_render_served_pages()` starts in a subprocess (via
# `port._app.start_app()`) to serve every page-kind sample as a function of
# `?sample=<name>`. It only needs to import this package and shiny -- both
# are guaranteed importable in the same environment this renderer runs in.
_SERVING_APP_SOURCE = '''\
"""Throwaway app started by bslib_react._catalog_render to serve page samples.

Not meant to be run by hand; render_markup_catalog() writes this into a
temp directory and starts it with port._app.start_app().
"""

from shiny import App, ui

from bslib_react._catalog import catalog_eval


def _app_ui(request):
    name = request.query_params.get("sample", "")
    try:
        return catalog_eval([name])[0]
    except ValueError:
        return ui.page_fluid(f"bslib-react markup server: unknown sample {name!r}")


def _server(input, output, session):
    pass


app = App(_app_ui, _server)
'''


def _pkg_version(name: str) -> str:
    return importlib.metadata.version(name)


def _bslib_vendored_version() -> str:
    """The bslib release py-shiny vendors, read from its internal ``_versions`` module.

    ``shiny._versions.bslib`` is a private attribute, not public API -- there
    is no supported way to ask py-shiny "what bslib markup are you shipping"
    otherwise. If a future py-shiny moves or renames it, fail soft: warn and
    record ``"unknown"`` rather than crash the whole render over a version
    string used for humans reading the catalog file, not for logic.
    """
    try:
        from shiny import _versions

        value = getattr(_versions, "bslib")  # noqa: B009
        return str(value)
    except Exception as exc:  # pragma: no cover - depends on shiny internals
        warnings.warn(
            "could not read the vendored bslib version from shiny._versions.bslib "
            f"({exc!r}); recording 'unknown'. This reads a private py-shiny path "
            "that may have moved -- update _bslib_vendored_version() if this "
            "warning persists after a shiny upgrade.",
            stacklevel=2,
        )
        return "unknown"


def markup_catalog_key(samples: Sequence[Sample] | None = None) -> str:
    """The cache key for a render of ``samples`` (the whole catalog, by default).

    Changes when ``shiny``, ``htmltools``, or the vendored bslib version
    change, when a sample's call text changes, or when ``renderer=`` (the
    render logic's own version) is bumped -- see ``docs/markup-catalog.md``.
    """
    return (
        f"py;shiny={_pkg_version('shiny')};htmltools={_pkg_version('htmltools')};"
        f"bslib_vendored={_bslib_vendored_version()};catalog={catalog_hash(samples)};"
        "renderer=1"
    )


def _render_tag_sample(sample: Sample, tag: "TagChild") -> dict:
    """Render one sample as an unserved tag: ``htmltools.TagList(tag).render()``."""
    rendered = TagList(tag).render()
    # sorted(set(...)): the contract requires deps sorted with no duplicates
    # (docs/markup-catalog.md), and htmltools can list the same dependency
    # more than once when several tags in a tree each declare it.
    deps = sorted({f"{dep.name}@{dep.version}" for dep in rendered["dependencies"]})
    return {
        "kind": sample.kind,
        "group": sample.group,
        "pkg": sample.pkg,
        "served": False,
        "call": sample.call,
        "html": rendered["html"],
        "html_attrs": None,
        "head_inline_css": [],
        "deps": deps,
        "skipped": None,
    }


class _ServedPageParser(HTMLParser):
    """Pulls ``<html>`` attrs, raw ``<body>...</body>``, and head ``<style>`` text.

    Kept deliberately literal: ``get_starttag_text()`` returns each tag's
    exact source text (original attribute order, quoting, and whitespace),
    so the captured body markup is a faithful copy of what was served, not a
    re-serialization -- matching the "html is raw, nothing is normalised
    here" rule in ``docs/markup-catalog.md``. ``convert_charrefs=False`` for
    the same reason: entity and character references are re-emitted as-is
    rather than being decoded away.

    Nesting-aware on purpose: when a page-kind sample's call already returns
    a complete ``<html>`` document (every ``page_*`` sample does), py-shiny's
    ``App`` embeds that whole document as a child inside its *own* base
    HTML page rather than serving it as-is -- unlike R shiny, which detects
    a full document and serves it directly. The wire response is therefore
    one ``<html>`` nested inside another. ``html_attrs`` keeps the last (so,
    innermost) ``<html>`` tag's attributes; body content is captured per
    nesting level and ``body_html`` returns the first one to *close*, which
    -- because tags nest LIFO -- is always the innermost, real one,
    regardless of how many levels deep it turns out to be.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.html_attrs: dict[str, str | None] = {}
        self.head_inline_css: list[str] = []
        self._completed_bodies: list[str] = []
        self._body_stack: list[list[str]] = []
        self._head_depth = 0
        self._in_style = False

    def _current_body_parts(self) -> list[str] | None:
        return self._body_stack[-1] if self._body_stack else None

    def _emit_open(self) -> None:
        parts = self._current_body_parts()
        if parts is not None:
            text = self.get_starttag_text()
            parts.append(text if text is not None else "")

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag == "html":
            # Overwritten on every occurrence: the last one seen is the
            # innermost, i.e. the sample's own page tag.
            self.html_attrs = dict(attrs)
            return
        if tag == "head":
            self._head_depth += 1
            return
        if tag == "style" and self._head_depth > 0:
            self._in_style = True
            self.head_inline_css.append("")
            return
        if tag == "body":
            # "outer HTML": the <body ...> tag itself is part of what gets
            # captured, not just its children.
            text = self.get_starttag_text()
            self._body_stack.append([text if text is not None else "<body>"])
            return
        self._emit_open()

    def handle_startendtag(self, tag: str, attrs) -> None:
        if tag == "html":
            self.html_attrs = dict(attrs)
            return
        self._emit_open()

    def handle_endtag(self, tag: str) -> None:
        if tag == "head":
            self._head_depth = max(0, self._head_depth - 1)
            return
        if tag == "style":
            self._in_style = False
            return
        if tag == "body":
            if self._body_stack:
                parts = self._body_stack.pop()
                parts.append("</body>")
                self._completed_bodies.append("".join(parts))
            return
        parts = self._current_body_parts()
        if parts is not None:
            parts.append(f"</{tag}>")

    def handle_data(self, data: str) -> None:
        if self._in_style:
            self.head_inline_css[-1] += data
            return
        parts = self._current_body_parts()
        if parts is not None:
            parts.append(data)

    def handle_entityref(self, name: str) -> None:
        parts = self._current_body_parts()
        if parts is not None:
            parts.append(f"&{name};")

    def handle_charref(self, name: str) -> None:
        parts = self._current_body_parts()
        if parts is not None:
            parts.append(f"&#{name};")

    @property
    def body_html(self) -> str:
        # The first body to finish is the most deeply nested one (tags
        # close LIFO), i.e. the real page -- not py-shiny's outer wrapper.
        return self._completed_bodies[0] if self._completed_bodies else ""


def _render_served_pages(
    page_samples: Sequence[Sample], *, quiet: bool
) -> dict[str, dict]:
    """Serve every page-kind sample from one background app and fetch each.

    Starts a tiny throwaway app (``_SERVING_APP_SOURCE``) with
    ``port._app.start_app()`` -- the same runner used to diff a port against
    its parent -- and fetches ``?sample=<name>`` for each sample name with
    the standard library only (``urllib.request``), as the contract requires.
    """
    # Imported lazily: this path is only exercised when `served` allows it,
    # and it pulls in `shiny.run`, which spawns a subprocess.
    from ._app_runner import start_app

    tmp_dir = Path(tempfile.mkdtemp(prefix="bslib_react_markup_"))
    (tmp_dir / "app.py").write_text(_SERVING_APP_SOURCE, encoding="utf-8")

    handle = start_app(tmp_dir, timeout=60)
    try:
        if not quiet:
            print(f"[bslib-react] serving page samples at {handle.url}")
        results: dict[str, dict] = {}
        for sample in page_samples:
            url = f"{handle.url}?sample={urllib.parse.quote(sample.name)}"
            with urllib.request.urlopen(url, timeout=20) as resp:
                html_text = resp.read().decode("utf-8")
            parser = _ServedPageParser()
            parser.feed(html_text)
            results[sample.name] = {
                "served": True,
                "html": parser.body_html,
                "html_attrs": parser.html_attrs,
                "head_inline_css": parser.head_inline_css,
            }
        return results
    finally:
        handle.stop()
        shutil.rmtree(tmp_dir, ignore_errors=True)


def render_markup_catalog(
    path: str | Path = ".cache/markup/py.json",
    *,
    components: Sequence[str] | None = None,
    served: ServedMode = "auto",
    cache: bool = True,
    quiet: bool = False,
) -> dict:
    """Render the markup catalog and write it to ``path`` as JSON (schema 1).

    Args:
        path: Where to write the JSON file. Parent directories are created
            as needed.
        components: Sample names to render, instead of the whole catalog.
            Unknown names raise ``ValueError``.
        served: ``"auto"`` (default) serves page-kind samples from a
            background app and falls back to an unserved tag-level render if
            that fails; ``"always"`` raises instead of falling back;
            ``"never"`` skips serving entirely.
        cache: When ``True`` (default) and ``path`` already holds a render
            whose ``"key"`` matches the key this render would use, return the
            existing content unchanged instead of re-rendering.
        quiet: Suppress the progress lines normally printed to stdout.

    Returns:
        The record that was written (or the cached one, on a cache hit), as
        a plain ``dict`` matching the schema in ``docs/markup-catalog.md``.
    """
    path = Path(path)

    if components is None:
        samples: tuple[Sample, ...] = SAMPLES
    else:
        by_name = {sample.name: sample for sample in SAMPLES}
        unknown = [name for name in components if name not in by_name]
        if unknown:
            raise ValueError(
                "render_markup_catalog(components=...) named unknown catalog "
                f"sample(s): {unknown}"
            )
        samples = tuple(by_name[name] for name in components)

    key = markup_catalog_key(samples)

    if cache and path.is_file():
        try:
            existing = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            existing = None
        if isinstance(existing, dict) and existing.get("key") == key:
            if not quiet:
                print(f"[bslib-react] markup catalog is up to date: {path}")
            return existing

    # Every sample gets an in-process, unserved render first. This is the
    # only way "tag" kind samples are ever rendered, and it also gives every
    # "page" kind sample a fallback (and its `deps`, which the served path
    # below has no reliable way to recover from raw response bytes alone).
    results: dict[str, dict] = {}
    for sample in samples:
        tag = catalog_eval([sample.name])[0]
        results[sample.name] = _render_tag_sample(sample, tag)

    page_samples = [sample for sample in samples if sample.kind == "page"]
    if page_samples and served != "never":
        try:
            served_json = _render_served_pages(page_samples, quiet=quiet)
            for name, info in served_json.items():
                results[name].update(info)
        except Exception as exc:
            if served == "always":
                raise
            if not quiet:
                print(
                    f"[bslib-react] could not serve page samples ({exc!r}); "
                    "falling back to unserved rendering for them"
                )

    record = {
        "schema": 1,
        "language": "py",
        "key": key,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "generator": {"package": "bslib-react", "version": __version__},
        "versions": {
            "shiny": _pkg_version("shiny"),
            "htmltools": _pkg_version("htmltools"),
            "bslib_vendored": _bslib_vendored_version(),
            "runtime": f"Python {platform.python_version()}",
        },
        "samples": results,
    }

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(record, f, indent=2, default=str)
    if not quiet:
        print(f"[bslib-react] wrote {path}")

    return record


__all__ = ["render_markup_catalog", "markup_catalog_key"]
