"""``host_input()``: mount one server-rendered Shiny widget inside a React page.

The ui.tsx pattern puts the client in charge of markup, but a handful of
widgets (a color picker, a fancy date range control, anything a team already
has a battle-tested ``renderUI`` for) are not worth rebuilding in React right
away. ``host_input()`` is the escape hatch: it registers an ordinary
``@render.ui`` output on the server, and hands back the output id your React
component should mount at (conventionally via a `<SliderInput id="bins_ui"
/>`-style hosted element).
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any, Callable, Protocol

from htmltools import Tag, TagList
from shiny import render

if TYPE_CHECKING:
    from htmltools import TagChild


class _OutputsLike(Protocol):
    """The one sliver of ``shiny.session.Outputs`` that ``host_input()`` needs.

    A structural type rather than importing ``Outputs`` itself: the real
    class and a test double both satisfy this without either one needing to
    inherit from the other, and it documents exactly what ``host_input()``
    depends on.
    """

    def __call__(
        self,
        renderer: Any = None,
        *,
        id: str | None = None,
        suspend_when_hidden: bool = True,
        priority: int = 0,
    ) -> Any: ...


def _check_no_id_collision(tag: "TagChild", name: str) -> None:
    """Raise ``ValueError`` if some element inside ``tag`` already has id ``name``.

    Walks ``Tag.children`` (a :class:`~htmltools.TagList`, which flattens
    nested lists as it is iterated) looking for an ``id`` attribute equal to
    ``name``. A collision means the widget's own markup would fight with the
    output wrapper Shiny binds to for the same DOM id, so it is caught here
    rather than left to produce a confusing duplicate-id bug in the browser.
    """
    if isinstance(tag, Tag):
        if tag.attrs.get("id") == name:
            raise ValueError(
                f"host_input(): the widget passed for id={name!r} contains its own "
                f"element with that same id. Give the widget a different id, or pass "
                "a different suffix= to host_input() so the output id it registers "
                "doesn't collide with markup the widget itself produces."
            )
        for child in tag.children:
            _check_no_id_collision(child, name)
    elif isinstance(tag, TagList):
        for child in tag:
            _check_no_id_collision(child, name)


def host_input(
    output: "_OutputsLike",
    id: str,
    widget: Callable[[], "TagChild"],
    suffix: str = "_ui",
) -> str:
    """Register ``widget`` as a hosted output and return its output id.

    Registers ``output[f"{id}{suffix}"]`` as an ``@render.ui`` output that
    calls ``widget()`` lazily -- once per render, the same as any other
    Shiny output -- and checks the result for an id collision (see
    :func:`_check_no_id_collision`) before returning it. The registration
    uses ``suspend_when_hidden=False``: Shiny normally skips rendering an
    output it believes is hidden, based on the *server-rendered* DOM
    visibility of its container, but a hosted output's container is a React
    element the client mounts on its own terms, which Shiny's own visibility
    tracking cannot see. Without this, a hosted widget can simply never
    render on some page shapes.

    Args:
        output: The ``output`` object from your server function.
        id: The base id. Your React element reads this output at
            ``f"{id}{suffix}"`` (the default suffix makes that ``"bins_ui"``
            for ``id="bins"``).
        widget: A zero-argument callable returning the widget's markup, e.g.
            ``lambda: ui.input_slider("bins", "Bins", 1, 50, 30)``. Called
            fresh on every render, exactly like the body of any
            ``@render.ui`` function.
        suffix: Appended to ``id`` to form the registered output name.

    Returns:
        The output name (``f"{id}{suffix}"``) the widget was registered
        under -- pass this straight to your React element's ``id`` prop.
    """
    name = f"{id}{suffix}"

    @output(id=name, suspend_when_hidden=False)
    @render.ui
    def _() -> "TagChild":
        tag = widget()
        _check_no_id_collision(tag, name)
        return tag

    return name
