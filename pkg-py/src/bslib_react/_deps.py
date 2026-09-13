"""``page_deps()``: the CSS/JS a bslib-react page needs, without a real page.

bslib-react's React components reproduce bslib markup, but some of that
markup depends on component CSS and JS that a normal bslib/shiny app only
picks up because the *components themselves* are somewhere on the page (the
ion.rangeSlider assets a slider needs, selectize's assets, bslib's own
component JS). A React page that never calls ``ui.input_slider()`` directly
still needs those files if it renders a `<SliderInput>`. ``page_deps()``
closes that gap: it renders a representative sample of the catalog (or a
caller-chosen subset) purely to ask htmltools what dependencies that markup
would pull in, then hands back just the dependency tags.
"""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING, Sequence

from htmltools import TagList
from shiny.ui import Theme

from ._catalog import catalog_eval, catalog_names

if TYPE_CHECKING:
    from htmltools import TagChild

# Every page function shiny ships (`page_bootstrap`, `page_navbar`, ...)
# attaches these itself. Including them here too would be harmless (htmltools
# de-duplicates dependencies by name when hoisting to <head>) but misleading:
# a caller reading page_deps()'s output should see only the extra things
# bslib-react needs, not the baseline every shiny page already has.
_ALWAYS_EXCLUDED = frozenset({"bootstrap", "jquery"})


def _validate_theme(theme: object) -> None:
    """Raise ``TypeError`` unless ``theme`` is one of the accepted shapes.

    Unlike R's ``page_deps()``, the value is otherwise unused here: py-shiny
    compiles component CSS (ion.rangeSlider, selectize, bslib's own component
    JS) into the *page's own* theme stylesheet at render time, keyed off
    whatever theme the page function itself was given -- there is no
    R-style ``bslib::bs_global_set()`` step to mirror. This validation exists
    so the same call signature works in both languages, and so a typo'd
    ``theme=`` argument fails loudly here rather than silently doing nothing.
    """
    if theme is None:
        return
    if isinstance(theme, (str, Path)):
        return
    if isinstance(theme, Theme):
        return
    raise TypeError(
        "page_deps(theme=...) must be None, a str or Path to a _brand.yml, "
        f"or a shiny.ui.Theme instance; got {type(theme).__name__}. "
        "py-shiny resolves component CSS against whatever theme the page "
        "itself declares, so this value is validated but otherwise unused."
    )


def page_deps(
    theme: str | Path | Theme | None = None,
    *extra: "TagChild",
    components: Sequence[str] | None = None,
) -> TagList:
    """The HTML dependencies bslib-react's components need at runtime.

    Attach the result to a shinyreact page alongside :func:`bslib_react_dep`,
    for example
    ``page_react(page_deps(app_theme), bslib_react_dep(), theme=app_theme)``.
    It works by rendering a representative sample of the markup catalog --
    the same sample calls the catalog renderer uses for ``bslib-react
    markup`` -- and reading back whichever :class:`~htmltools.HTMLDependency`
    objects that markup pulled in, minus the ones every shiny page already
    attaches on its own (``bootstrap``, ``jquery``).

    Args:
        theme: Accepted so the same call signature exists in R and Python;
            py-shiny resolves component CSS against whatever theme the page
            itself declares, so this value is validated (must be ``None``, a
            ``str``/``Path`` to a ``_brand.yml``, or a
            :class:`shiny.ui.Theme`) but otherwise unused. Pass your page's
            real theme here anyway -- it keeps the call symmetric with R's
            ``page_deps()``, and a future py-shiny that *does* need it here
            will not require an API change.
        *extra: Additional tags to render alongside the catalog sample --
            typically the actual inputs and outputs your page uses, so their
            dependencies are included too even if the catalog doesn't happen
            to cover them.
        components: Catalog sample names to render, instead of every
            ``"tag"``/``"page"`` sample. Pass ``[]`` to render none of the
            catalog (only ``*extra``). Unknown names raise ``ValueError``.

    Returns:
        A :class:`~htmltools.TagList` of :class:`~htmltools.HTMLDependency`
        objects, ready to splat into a page.
    """
    _validate_theme(theme)

    if components is None:
        names: Sequence[str] = catalog_names(("tag", "page"))
    else:
        names = list(components)
        known = set(catalog_names())
        for name in names:
            if name not in known:
                raise ValueError(
                    "page_deps(components=...) named an unknown catalog "
                    f"sample: {name!r}"
                )

    samples = catalog_eval(names)
    rendered = TagList(*samples, *extra).tagify()
    deps = rendered.get_dependencies()
    return TagList(*(dep for dep in deps if dep.name not in _ALWAYS_EXCLUDED))
