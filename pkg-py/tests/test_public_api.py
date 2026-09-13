"""The top-level public API is exactly what's documented, no more, no less."""

import bslib_react

_EXPECTED = [
    "__version__",
    "bslib_react_dep",
    "host_input",
    "page_deps",
]


def test_dunder_all_matches_documented_api() -> None:
    assert sorted(bslib_react.__all__) == sorted(_EXPECTED)


def test_every_exported_name_is_actually_importable() -> None:
    for name in bslib_react.__all__:
        assert hasattr(bslib_react, name), (
            f"bslib_react.__all__ names {name!r}, but it isn't defined"
        )
