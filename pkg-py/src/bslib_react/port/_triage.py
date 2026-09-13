"""Take stock of a parent Shiny app before porting it.

Ported from ``tools/port/triage.R``: prints what the app is built from (page
function, theme, every input/output call with a count and first location,
dynamic UI, modules, packages, static files, data, tests), so the output can
be pasted into ``PORT.md``. Reads the source and never runs the app (unless
``run=True``), so it finishes in a fraction of a second.

Scans ``*.py`` files with :mod:`ast` (real parsing, not text matching) and
``*.R``/``*.r`` files with the same regex approach ``triage.R`` uses on
itself, so a Python user can triage an R parent app too -- useful when the
"parent" being ported is an R app and the port is being written in Python.
"""

from __future__ import annotations

import ast
import re
from dataclasses import dataclass, field
from pathlib import Path

from ._catalogs import (
    DYNAMIC_UI_FNS as _DYNAMIC_UI_FNS,
)
from ._catalogs import (
    INPUT_FNS as _INPUT_FNS,
)
from ._catalogs import (
    LAYOUT_FNS as _LAYOUT_FNS,
)
from ._catalogs import (
    OUTPUT_FNS as _OUTPUT_FNS,
)
from ._catalogs import (
    PAGE_FNS as _PAGE_FNS,
)
from ._catalogs import (
    PKG_ROLE as _PKG_ROLE,
)
from ._catalogs import (
    R_DYNAMIC_UI_FNS as _R_DYNAMIC_UI_FNS,
)
from ._catalogs import (
    R_INPUT_FNS as _R_INPUT_FNS,
)
from ._catalogs import (
    R_LAYOUT_FNS as _R_LAYOUT_FNS,
)
from ._catalogs import (
    R_OUTPUT_FNS as _R_OUTPUT_FNS,
)
from ._catalogs import (
    R_PAGE_FNS as _R_PAGE_FNS,
)
from ._catalogs import (
    R_REACTIVITY_FNS as _R_REACTIVITY_FNS,
)
from ._catalogs import (
    REACTIVITY_ATTRS as _REACTIVITY_ATTRS,
)
from ._catalogs import (
    SKIP_DIRS as _SKIP_DIRS,
)


@dataclass
class CallHit:
    """One counted call: how many times, and where it first appears."""

    name: str
    n: int
    where: str


@dataclass
class TriageReport:
    """The structured result of :func:`triage`. ``str()`` gives a Markdown block."""

    name: str
    dir: Path
    py_files: int = 0
    r_files: int = 0
    code_lines: int = 0
    largest_files: list[tuple[str, int]] = field(default_factory=list)
    page_hits: list[CallHit] = field(default_factory=list)
    theme_line: str | None = None
    has_brand_yml: bool = False
    input_hits: list[CallHit] = field(default_factory=list)
    output_hits: list[CallHit] = field(default_factory=list)
    render_hits: list[CallHit] = field(default_factory=list)
    dynamic_ui_hits: list[CallHit] = field(default_factory=list)
    layout_hits: list[CallHit] = field(default_factory=list)
    module_ui_names: list[str] = field(default_factory=list)
    module_server_names: list[str] = field(default_factory=list)
    reactivity_hits: list[CallHit] = field(default_factory=list)
    packages: list[tuple[str, str]] = field(default_factory=list)
    www_files: list[tuple[str, int, bool]] = field(default_factory=list)
    data_files: list[tuple[str, int, bool]] = field(default_factory=list)
    test_files: list[str] = field(default_factory=list)
    env_files_present: dict[str, bool] = field(default_factory=dict)
    notes: list[str] = field(default_factory=list)
    launch: dict | None = None

    def to_markdown(self) -> str:
        lines: list[str] = [f"# Triage: {self.name}", str(self.dir), ""]

        def header(title: str) -> None:
            lines.append(f"## {title}")

        def hits(items: list[CallHit], empty: str = "none") -> None:
            if not items:
                lines.append(f"- {empty}")
                return
            for h in items:
                lines.append(f"- {h.name}: {h.n} ({h.where})")

        header("Size")
        lines.append(f"- Python files: {self.py_files}")
        lines.append(f"- R files: {self.r_files}")
        lines.append(f"- code lines (no blanks, no comments): {self.code_lines}")
        if self.largest_files:
            largest = ", ".join(f"{f} ({n})" for f, n in self.largest_files)
            lines.append(f"- largest: {largest}")

        header("Page and theme")
        hits(self.page_hits, "no page function found")
        lines.append(f"- theme: {self.theme_line or 'none'}")
        lines.append(f"- _brand.yml: {'yes' if self.has_brand_yml else 'no'}")

        header("Inputs")
        hits(self.input_hits)
        lines.append(f"- total input calls: {sum(h.n for h in self.input_hits)}")

        header("Outputs")
        hits(self.output_hits)
        lines.append(f"- total output calls: {sum(h.n for h in self.output_hits)}")
        lines.append("- render calls:")
        hits(self.render_hits)

        header("Dynamic UI (each one is a Level H or Level R decision)")
        hits(self.dynamic_ui_hits)

        header("Layout")
        hits(self.layout_hits)

        header("Modules")
        lines.append(
            "- ui functions: "
            + (", ".join(self.module_ui_names) if self.module_ui_names else "none")
        )
        lines.append(
            "- server functions: "
            + (
                ", ".join(self.module_server_names)
                if self.module_server_names
                else "none"
            )
        )

        header("Reactivity")
        hits(self.reactivity_hits)

        header("Packages")
        if not self.packages:
            lines.append("- none")
        for pkg, role in self.packages:
            lines.append(f"- {pkg}" + (f"  [{role}]" if role else ""))

        header("Static files (www)")
        if not self.www_files:
            lines.append("- no www folder")
        for path, size, talks_to_shiny in self.www_files:
            flag = "  [talks to Shiny]" if talks_to_shiny else ""
            lines.append(f"- {path} ({_fmt_size(size)}){flag}")

        header("Data")
        if not self.data_files:
            lines.append("- no data folder")
        for path, size, big in self.data_files:
            flag = "  [over the 500 KB commit hook limit]" if big else ""
            lines.append(f"- {path} ({_fmt_size(size)}){flag}")

        header("Tests and env files")
        lines.append(f"- test files: {len(self.test_files)}")
        for key, present in self.env_files_present.items():
            lines.append(f"- {key}: {'present' if present else 'absent'}")

        header("Notes")
        for note in self.notes or ["Nothing unusual."]:
            lines.append(f"- {note}")

        if self.launch is not None:
            header("Launch")
            if self.launch.get("failed"):
                lines.append(f"- failed: {self.launch['failed']}")
            else:
                lines.append(f"- answers at {self.launch['url']}")
                errs = self.launch.get("errors", [])
                lines.append(f"- log errors in the first seconds: {len(errs)}")
                for e in errs[:10]:
                    lines.append(f"  {e}")

        return "\n".join(lines) + "\n"

    def __str__(self) -> str:
        return self.to_markdown()


def _fmt_size(num_bytes: int) -> str:
    if num_bytes >= 1_000_000:
        return f"{num_bytes / 1_000_000:.1f} MB"
    return f"{num_bytes / 1_000:.0f} KB"


def _app_dir_name(directory: Path) -> str:
    from ._app import _app_name

    return _app_name(directory)


def _iter_source_files(directory: Path, suffixes: tuple[str, ...]) -> list[Path]:
    found: list[Path] = []
    for path in directory.rglob("*"):
        if not path.is_file() or path.suffix not in suffixes:
            continue
        if any(part in _SKIP_DIRS for part in path.relative_to(directory).parts[:-1]):
            continue
        found.append(path)
    return sorted(found)


def _dotted_name(node: ast.AST) -> str | None:
    """Best-effort dotted name for a Call's ``func`` or a decorator expression."""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        base = _dotted_name(node.value)
        return f"{base}.{node.attr}" if base else node.attr
    if isinstance(node, ast.Call):
        return _dotted_name(node.func)
    return None


class _PyCollector:
    """One pass over a Python file's AST, tallying calls into named groups."""

    def __init__(self) -> None:
        self.counts: dict[str, dict[str, tuple[int, str]]] = {
            "page": {},
            "input": {},
            "output": {},
            "render": {},
            "dynamic_ui": {},
            "layout": {},
            "reactivity": {},
        }
        self.module_ui: list[str] = []
        self.module_server: list[str] = []
        self.theme_line: str | None = None
        self.imports: set[str] = set()

    def _bump(self, group: str, name: str, rel: str, lineno: int) -> None:
        bucket = self.counts[group]
        n, where = bucket.get(name, (0, f"{rel}:{lineno}"))
        bucket[name] = (n + 1, where)

    def visit_file(self, tree: ast.AST, rel: str) -> None:
        for node in ast.walk(tree):
            if isinstance(node, (ast.Import, ast.ImportFrom)):
                mod = getattr(node, "module", None) or ""
                for alias in node.names:
                    top = (mod or alias.name).split(".")[0]
                    if top:
                        self.imports.add(top)
            elif isinstance(node, ast.Call):
                dotted = _dotted_name(node.func)
                if dotted is None:
                    continue
                leaf = dotted.rsplit(".", 1)[-1]
                if leaf in ("Theme", "from_brand") and self.theme_line is None:
                    self.theme_line = f"{rel}:{node.lineno}"
                if leaf in _PAGE_FNS:
                    self._bump("page", leaf, rel, node.lineno)
                if leaf in _INPUT_FNS:
                    self._bump("input", leaf, rel, node.lineno)
                if leaf in _OUTPUT_FNS:
                    self._bump("output", leaf, rel, node.lineno)
                if leaf in _DYNAMIC_UI_FNS:
                    self._bump("dynamic_ui", leaf, rel, node.lineno)
                if leaf in _LAYOUT_FNS:
                    self._bump("layout", leaf, rel, node.lineno)
                if dotted.startswith("reactive.") and leaf in _REACTIVITY_ATTRS:
                    self._bump("reactivity", f"reactive.{leaf}", rel, node.lineno)
            elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                for dec in node.decorator_list:
                    dotted = _dotted_name(dec)
                    if dotted is None:
                        continue
                    if dotted.startswith("render.") or dotted == "render":
                        self._bump("render", dotted, rel, node.lineno)
                    elif dotted in ("module.ui",):
                        self.module_ui.append(node.name)
                    elif dotted in ("module.server",):
                        self.module_server.append(node.name)
                    elif (
                        dotted.startswith("reactive.")
                        and dotted.rsplit(".", 1)[-1] in _REACTIVITY_ATTRS
                    ):
                        self._bump("reactivity", dotted, rel, node.lineno)


def _collect_python(files: list[Path], directory: Path) -> _PyCollector:
    collector = _PyCollector()
    for path in files:
        rel = str(path.relative_to(directory)).replace("\\", "/")
        try:
            tree = ast.parse(
                path.read_text(encoding="utf-8", errors="replace"), filename=rel
            )
        except SyntaxError:
            continue
        collector.visit_file(tree, rel)
    return collector


def _regex_count_r(
    files: list[Path], directory: Path, names: set[str]
) -> dict[str, tuple[int, str]]:
    result: dict[str, tuple[int, str]] = {}
    for path in files:
        rel = str(path.relative_to(directory)).replace("\\", "/")
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for lineno, raw in enumerate(lines, start=1):
            code = re.sub(r"#.*$", "", raw)
            for name in names:
                pattern = r"(^|[^A-Za-z0-9_.$])" + re.escape(name) + r"\s*\("
                if re.search(pattern, code):
                    n, where = result.get(name, (0, f"{rel}:{lineno}"))
                    result[name] = (n + 1, where)
    return result


def _to_hits(counts: dict[str, tuple[int, str]]) -> list[CallHit]:
    return [
        CallHit(name=name, n=n, where=where)
        for name, (n, where) in sorted(counts.items())
    ]


def _merge_hits(a: list[CallHit], b: list[CallHit]) -> list[CallHit]:
    by_name = {h.name: h for h in a}
    for h in b:
        if h.name in by_name:
            existing = by_name[h.name]
            by_name[h.name] = CallHit(
                name=h.name, n=existing.n + h.n, where=existing.where
            )
        else:
            by_name[h.name] = h
    return sorted(by_name.values(), key=lambda h: h.name)


def triage(dir: str | Path, *, run: bool = False) -> TriageReport:
    """Take stock of a parent (or in-progress port) app in ``dir``.

    Reads every ``*.py`` file with :mod:`ast` and every ``*.R``/``*.r`` file
    with a regex pass, and never runs the app unless ``run=True``.

    Args:
        dir: The app's directory.
        run: Also start the app (via :func:`bslib_react.port.start_app`) and
            report whether it answers and what its log shows in the first
            few seconds.

    Returns:
        A :class:`TriageReport`. ``print(report)`` (or ``str(report)``)
        gives a Markdown block suitable for pasting into ``PORT.md``.
    """
    directory = Path(dir)
    if not directory.is_dir():
        raise FileNotFoundError(f"app directory not found: {directory}")

    py_files = _iter_source_files(directory, (".py",))
    r_files = _iter_source_files(directory, (".R", ".r"))

    collector = _collect_python(py_files, directory)

    r_input = _regex_count_r(r_files, directory, _R_INPUT_FNS)
    r_output = _regex_count_r(r_files, directory, _R_OUTPUT_FNS)
    r_page = _regex_count_r(r_files, directory, _R_PAGE_FNS)
    r_dynamic = _regex_count_r(r_files, directory, _R_DYNAMIC_UI_FNS)
    r_layout = _regex_count_r(r_files, directory, _R_LAYOUT_FNS)
    r_reactivity = _regex_count_r(r_files, directory, _R_REACTIVITY_FNS)

    page_hits = _merge_hits(_to_hits(collector.counts["page"]), _to_hits(r_page))
    input_hits = _merge_hits(_to_hits(collector.counts["input"]), _to_hits(r_input))
    output_hits = _merge_hits(_to_hits(collector.counts["output"]), _to_hits(r_output))
    dynamic_ui_hits = _merge_hits(
        _to_hits(collector.counts["dynamic_ui"]), _to_hits(r_dynamic)
    )
    layout_hits = _merge_hits(_to_hits(collector.counts["layout"]), _to_hits(r_layout))
    reactivity_hits = _merge_hits(
        _to_hits(collector.counts["reactivity"]), _to_hits(r_reactivity)
    )
    render_hits = _to_hits(collector.counts["render"])

    # Code line count, blanks and comments dropped -- mirrors triage.R's own
    # (equally naive) `sub("#.*$", "", line)` approach: a `#` inside a string
    # literal is still treated as a comment start. Consistent with the R
    # tool it ports, not a bug.
    code_lines = 0
    file_line_counts: list[tuple[str, int]] = []
    for path in [*py_files, *r_files]:
        rel = str(path.relative_to(directory)).replace("\\", "/")
        raw_lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        stripped = [re.sub(r"#.*$", "", line).strip() for line in raw_lines]
        nonblank = sum(1 for line in stripped if line)
        code_lines += nonblank
        file_line_counts.append((rel, nonblank))
    largest = sorted(file_line_counts, key=lambda x: x[1], reverse=True)[:6]

    packages = sorted((pkg, _PKG_ROLE.get(pkg, "")) for pkg in collector.imports)

    www_dir = directory / "www"
    www_files: list[tuple[str, int, bool]] = []
    if www_dir.is_dir():
        for path in sorted(www_dir.rglob("*")):
            if not path.is_file() or path.name in ("ui.js", "ui.css"):
                continue
            talks_to_shiny = False
            if path.suffix == ".js":
                text = path.read_text(encoding="utf-8", errors="replace")
                talks_to_shiny = "Shiny." in text
            rel = str(path.relative_to(directory)).replace("\\", "/")
            www_files.append((rel, path.stat().st_size, talks_to_shiny))

    data_dir = directory / "data"
    data_files: list[tuple[str, int, bool]] = []
    if data_dir.is_dir():
        for path in sorted(data_dir.rglob("*")):
            if not path.is_file():
                continue
            size = path.stat().st_size
            rel = str(path.relative_to(directory)).replace("\\", "/")
            data_files.append((rel, size, size > 500_000))

    tests_dir = directory / "tests"
    test_files = []
    if tests_dir.is_dir():
        test_files = [
            str(p.relative_to(directory)).replace("\\", "/")
            for p in tests_dir.rglob("test*")
            if p.is_file() and p.suffix in (".py", ".R", ".r")
        ]

    env_files_present = {
        name: (directory / name).exists()
        for name in (
            "pyproject.toml",
            "requirements.txt",
            "_brand.yml",
            ".env",
            "README.md",
        )
    }

    notes: list[str] = []
    if collector.theme_line is None and not page_hits:
        notes.append(
            "No theme and no page function found. Build the page shell "
            "explicitly and run deps_diff() after the first slice."
        )
    if (
        code_lines < 150
        or (sum(h.n for h in input_hits) + sum(h.n for h in output_hits)) < 3
    ):
        notes.append(
            "This looks like a skeleton, not a finished app. Check with the "
            "owner before porting."
        )
    n_render_ui = sum(
        h.n for h in dynamic_ui_hits if h.name in ("output_ui", "uiOutput", "renderUI")
    )
    if n_render_ui:
        notes.append(
            f"{n_render_ui} dynamic-UI call(s) found. For each one decide: "
            "a plain data-driven re-render, or a hosted widget via host_input()."
        )
    if any(size > 500_000 for _, size, _ in data_files):
        notes.append(
            "A data file is over 500 KB. Add a targeted exclude for it "
            "before committing."
        )
    if env_files_present.get(".env"):
        notes.append(
            "The parent has a .env file. Never copy it. The port reads the "
            "same keys the same way."
        )

    report = TriageReport(
        name=_app_dir_name(directory),
        dir=directory,
        py_files=len(py_files),
        r_files=len(r_files),
        code_lines=code_lines,
        largest_files=largest,
        page_hits=page_hits,
        theme_line=collector.theme_line,
        has_brand_yml=env_files_present.get("_brand.yml", False),
        input_hits=input_hits,
        output_hits=output_hits,
        render_hits=render_hits,
        dynamic_ui_hits=dynamic_ui_hits,
        layout_hits=layout_hits,
        module_ui_names=collector.module_ui,
        module_server_names=collector.module_server,
        reactivity_hits=reactivity_hits,
        packages=packages,
        www_files=www_files,
        data_files=data_files,
        test_files=test_files,
        env_files_present=env_files_present,
        notes=notes,
    )

    if run:
        from ._app import start_app

        try:
            handle = start_app(directory, timeout=60)
        except Exception as exc:
            report.launch = {"failed": str(exc)}
        else:
            errors = handle.log_errors()
            report.launch = {"url": handle.url, "errors": errors}
            handle.stop()

    return report
