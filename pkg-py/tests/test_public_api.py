"""The top-level public API is exactly what's documented, no more, no less."""

import bslibreact

_EXPECTED = [
    "__version__",
    "bslibreact_dep",
    "host_input",
    "page_deps",
]


def test_dunder_all_matches_documented_api() -> None:
    assert sorted(bslibreact.__all__) == sorted(_EXPECTED)


def test_every_exported_name_is_actually_importable() -> None:
    for name in bslibreact.__all__:
        assert hasattr(bslibreact, name), (
            f"bslibreact.__all__ names {name!r}, but it isn't defined"
        )
