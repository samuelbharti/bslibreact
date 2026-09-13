"""The ``bslib-react`` console script: a thin argparse wrapper.

Every subcommand delegates straight to an already-tested function elsewhere
in this package -- ``markup`` to :func:`bslib_react.render_markup_catalog`,
``triage``/``deps-diff``/``peek`` to :mod:`bslib_react.port`, ``create-app``
to :func:`bslib_react.create_app`. This module's only job is argument
parsing and turning each function's result into stdout text and an exit
code.
"""

from __future__ import annotations

import argparse
import sys
from typing import Sequence


def _cmd_markup(args: argparse.Namespace) -> int:
    from ._catalog_render import markup_catalog_key, render_markup_catalog

    if args.key:
        print(markup_catalog_key())
        return 0
    render_markup_catalog(args.out, served=args.served)
    return 0


def _cmd_triage(args: argparse.Namespace) -> int:
    from .port import triage

    print(triage(args.dir, run=args.run))
    return 0


def _cmd_deps_diff(args: argparse.Namespace) -> int:
    from .port import deps_diff

    result = deps_diff(
        args.parent,
        args.port,
        parent_url=args.parent_url,
        port_url=args.port_url,
        verbose=args.verbose,
    )
    print(result)
    return min(result.n, 100)


def _cmd_peek(args: argparse.Namespace) -> int:
    from .port import peek

    result = peek(
        args.port,
        parent=args.parent,
        select=args.select or (),
        click=args.click,
        out=args.out,
        width=args.width,
        height=args.height,
        all_console=args.all_console,
    )
    print(result)
    return 0


def _cmd_create_app(args: argparse.Namespace) -> int:
    from ._scaffold import create_app

    dest = create_app(args.path, name=args.name, title=args.title, brand=args.brand)
    print(f"created {dest}")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="bslib-react")
    sub = parser.add_subparsers(dest="command", required=True)

    p_markup = sub.add_parser("markup", help="render the markup catalog")
    p_markup.add_argument("--out", default=".cache/markup/py.json")
    p_markup.add_argument(
        "--served", choices=("auto", "never", "always"), default="auto"
    )
    p_markup.add_argument(
        "--key", action="store_true", help="print the cache key and exit"
    )
    p_markup.set_defaults(func=_cmd_markup)

    p_triage = sub.add_parser("triage", help="take stock of a parent app")
    p_triage.add_argument("dir")
    p_triage.add_argument("--run", action="store_true")
    p_triage.set_defaults(func=_cmd_triage)

    p_dd = sub.add_parser(
        "deps-diff", help="diff a parent app's dependencies against a port"
    )
    p_dd.add_argument("parent", nargs="?")
    p_dd.add_argument("port", nargs="?")
    p_dd.add_argument("--parent-url")
    p_dd.add_argument("--port-url")
    p_dd.add_argument("--verbose", action="store_true")
    p_dd.set_defaults(func=_cmd_deps_diff)

    p_peek = sub.add_parser("peek", help="look at a running port in a headless browser")
    p_peek.add_argument("port")
    p_peek.add_argument("--parent")
    p_peek.add_argument("--select", action="append")
    p_peek.add_argument("--click")
    p_peek.add_argument("--out")
    p_peek.add_argument("--width", type=int, default=1400)
    p_peek.add_argument("--height", type=int, default=900)
    p_peek.add_argument("--all-console", action="store_true")
    p_peek.set_defaults(func=_cmd_peek)

    p_create = sub.add_parser("create-app", help="scaffold a new bslib-react app")
    p_create.add_argument("path")
    p_create.add_argument("--name")
    p_create.add_argument("--title")
    p_create.add_argument("--brand", action="store_true")
    p_create.set_defaults(func=_cmd_create_app)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Entry point for the ``bslib-react`` console script."""
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
