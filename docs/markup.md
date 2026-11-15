# Markup map

Two different things live in this kit, and they are tested differently.

Layout, page shell, and output components reproduce bslib's or shiny's own
markup in TSX. Each one is pinned against a sample in the markup catalog,
rendered live from an installed bslib and py-shiny, with no committed
fixture. See `docs/markup-catalog.md` for how that works and
`docs/decisions/0001-no-fixtures-live-ground-truth.md` for why.

Input widgets (`SliderInput`, `SelectInput`, and the rest under
`pkg-js/src/inputs/`) do not reproduce any markup at all. Every one of
them is `HostedInput`, hosting one `output$<id>_ui <- renderUI(...)` or
`@render.ui` block the app itself defines, under an `_ui` suffixed name
different from the widget's own input id. There is nothing to pin, since
the widget's HTML comes from the server at runtime, not from TSX.

## Layout, page shell, and output components

| R | Python | TSX | Catalog sample |
| --- | --- | --- | --- |
| `shiny::plotOutput()` | `ui.output_plot()` | `PlotOutput` | `plotOutput` |
| `shiny::plotOutput(click = )` | `ui.output_plot(click = True)` | `PlotOutput` with `click` | `plotOutput_click` |
| `shiny::textOutput()` | `ui.output_text()` | `TextOutput` | `textOutput` |
| `shiny::verbatimTextOutput()` | `ui.output_code(placeholder = False)` | `VerbatimTextOutput` | `verbatimTextOutput` |
| `bslib::layout_columns()` | `ui.layout_columns()` | `LayoutColumns` | `layout_columns_value_box`, `layout_columns_fill`, `layout_columns_single_child` |
| `bslib::value_box()` | `ui.value_box()` | `ValueBox` | `value_box` |
| `DT::DTOutput()` | (no equivalent) | `DTOutput` | `DTOutput`, `DTOutput_no_fill` |
| `reactable::reactableOutput()` | (no equivalent) | `ReactableOutput` | `reactableOutput` |
| any other htmlwidget's `*Output()` | `shinywidgets` equivalents | `WidgetOutput` with `widgetClass` | `htmlwidget_output` |
| `shiny::uiOutput()` / `renderUI()` | `ui.output_ui()` / `@render.ui` | `UiOutput` | `uiOutput`, `uiOutput_fill`, `uiOutput_inline` |
| `bslib::page_fillable()` | `ui.page_fillable()` | `PageFillable` | `page_fillable`, `page_fillable_default` |
| `bslib::card()` | `ui.card()` | `Card`, `CardHeader`, `CardBody` | `card_full_screen`, `card_footer`, `card_id`, `card_height`, `card_no_fill` |
| `bslib::tooltip()` | `ui.tooltip()` | `Tooltip` | `tooltip` |
| `bslib::popover()` | `ui.popover()` | not yet built | `popover` |
| `bslib::page_sidebar()` | `ui.page_sidebar()` | `PageSidebar` | `sidebar_layout` |
| `bslib::layout_sidebar()` + `sidebar()` | `ui.layout_sidebar()` + `ui.sidebar()` | `LayoutSidebar` | `sidebar_layout`, `sidebar_layout_titled`, `sidebar_layout_right_closed`, `sidebar_custom_class`, `sidebar_layout_gap_padding` |
| `bslib::page_navbar()` shell | `ui.page_navbar()` | `PageNavbar` | `page_navbar`, `page_navbar_icon`, `page_navbar_sidebar`, `page_navbar_not_fillable` |
| the tab strip `page_navbar()`/`nav_panel()` build | `ui.nav_panel()` | `NavbarTabStrip`, `NavSpacer`, `NavItem` | `page_navbar`, `page_navbar_icon`, `page_navbar_dropdown` |
| one `nav_panel()`'s content area | `ui.nav_panel()` | `TabPane` | `page_navbar` |
| `shiny::navbarMenu()` / `bslib::nav_menu()` | `ui.nav_menu()` | `NavbarTabStrip`'s `NavDropdownDef` | `page_navbar_dropdown` |
| `bslib::accordion()` | `ui.accordion()` | not yet built | `accordion` |
| `bslib::input_dark_mode()` | `ui.input_dark_mode()` | `DarkModeInput` | `input_dark_mode` |

Not yet built as a reusable kit component: `navset_card_tab`/`navset_pill`
(the card embedded tab styles, as opposed to the navbar's own tab strip
above), a generic `Accordion`/`AccordionPanel`, `bslib::popover()`.
`plotly` has no dedicated component; use `WidgetOutput` for it.

## Input widgets

Every row here is `HostedInput`, called by the named export; the name is
only there for readability at the call site (`<SliderInput id="lfc_ui" />`),
it carries no widget specific props of its own.

| R | Python | TSX |
| --- | --- | --- |
| `shiny::sliderInput()` | `ui.input_slider()` | `SliderInput` |
| `shiny::selectInput()` | `ui.input_select()` | `SelectInput` |
| `shiny::selectizeInput()` | `ui.input_selectize()` | `SelectizeInput` |
| `shiny::radioButtons()` | `ui.input_radio_buttons()` | `RadioButtons` |
| `shiny::checkboxInput()` | `ui.input_checkbox()` | `CheckboxInput` |
| `shiny::textInput()` | `ui.input_text()` | `TextInput` |
| `shiny::textAreaInput()` | `ui.input_text_area()` | `TextAreaInput` |
| `shiny::numericInput()` | `ui.input_numeric()` | `NumericInput` |
| `shiny::passwordInput()` | `ui.input_password()` | `PasswordInput` |
| `shiny::actionButton()` | `ui.input_action_button()` | `ActionButton` |
| `shiny::actionLink()` | `ui.input_action_link()` | `ActionLink` |
| `shiny::downloadButton()` | `ui.download_button()` | `DownloadButton` |
| `shiny::fileInput()` | `ui.input_file()` | `FileInput` |

## Widgets that still write their own markup by hand

Not every hosted element can go through a single `renderUI()` output:
something mixed into markup the client itself owns, a hosted tab link that
is one `<li>` among React rendered siblings, cannot be swapped in as a
whole `renderUI()` output. `NavbarTabStrip` is the one case in this kit: it
writes its own `<ul>` by hand and binds itself as a Shiny input through
`useBoundScope()`, the same mechanism `LayoutSidebar` uses for a sidebar
given an `id`. See `docs/decisions/0003-hosted-widgets.md` for why, and
each component's own source comment for the mechanism.
