import type { ReactElement } from "react";
import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import {
  catalogClasses,
  catalogShape,
  describeCatalog,
  renderShape,
  sample,
  shapeOf,
} from "./catalog";
import { NavbarTabStrip, NavSpacer, NavItem } from "../src/nav/NavbarTabStrip";
import { TabPane } from "../src/nav/TabPane";
import { Card, CardBody, CardFooter, CardHeader } from "../src/card/Card";
import { ValueBox } from "../src/card/ValueBox";
import { LayoutColumns } from "../src/layout/LayoutColumns";
import { LayoutSidebar } from "../src/layout/Sidebar";
import { PageFillable } from "../src/page/PageFillable";
import { PageSidebar } from "../src/page/PageSidebar";
import { PageNavbar } from "../src/page/PageNavbar";
import { Tooltip } from "../src/tooltip/Tooltip";
import { PlotOutput } from "../src/outputs/PlotOutput";
import { TextOutput, VerbatimTextOutput } from "../src/outputs/TextOutput";
import { DTOutput } from "../src/outputs/DTOutput";
import { ReactableOutput } from "../src/outputs/ReactableOutput";
import { WidgetOutput } from "../src/outputs/WidgetOutput";
import { UiOutput } from "../src/outputs/UiOutput";
import { HelpText } from "../src/misc/HelpText";
import { HostedInput } from "../src/inputs/HostedInput";
import { Module } from "../src/module/Module";

/**
 * The kit's markup, checked against the HTML bslib actually emits, rendered
 * live from an installed bslib, not read from a committed fixture -
 * see tests/catalog.ts for what that comparison does and does not cover,
 * and docs/decisions/0001-no-fixtures-live-ground-truth.md at the repo root
 * for why. Every describe block below is wrapped in describeCatalog(), which
 * skips (with the reason in the title) instead of failing when the R
 * catalog is not ready this run - see tests/global-setup.ts.
 *
 * Components read their hooks off window.shinyreact, which tests/setup.ts
 * installs (the real @posit-dev/shinyreact package, the same one a real
 * page's shinyreact.js dependency would provide) before every test file
 * runs. Nothing here needs a live window.Shiny: with no window.Shiny
 * present, useBoundScope resolves to "ready" immediately (see its own file
 * comment), so every component below renders its full markup, hosted
 * outputs included, on the very first render - these tests are about the
 * markup React renders, not about binding, which is bind.test.tsx's job.
 */
const panels = [
  { value: "Browse", label: "Browse" },
  { value: "Overview", label: "Overview" },
];

describeCatalog("r", "NavbarTabStrip", () => {
  it("renders the <ul> bslib's page_navbar() renders", () => {
    const { container } = render(<NavbarTabStrip id="nav" panels={panels} />);
    const ul = container.querySelector("ul");
    expect(shapeOf(ul)).toEqual(catalogShape("page_navbar", "ul.shiny-tab-input"));
  });

  // The regression this whole file exists for. bslib's nav-underline CSS
  // needs "active" on the <a>, and Shiny's BootstrapTabInputBinding reads
  // the current tab with `.nav-link:not(.dropdown-toggle).active`. The kit
  // once put "active" on the <li> and no class at all on the <a>, which
  // shipped in four apps before a screenshot diff caught it.
  it("puts nav-item on every <li>", () => {
    const { container } = render(<NavbarTabStrip id="nav" panels={panels} />);
    const lis = container.querySelectorAll("ul.shiny-tab-input > li");
    const expected = catalogClasses("page_navbar", "ul.shiny-tab-input > li");
    for (const li of Array.from(lis)) {
      expect(Array.from(li.classList).sort()).toEqual(expected);
    }
  });

  it("puts nav-link on every tab link, and active only on the first", () => {
    const { container } = render(<NavbarTabStrip id="nav" panels={panels} />);
    const links = Array.from(container.querySelectorAll("ul.shiny-tab-input > li > a"));

    expect(Array.from(links[0]!.classList).sort()).toEqual(
      catalogClasses("page_navbar", "ul.shiny-tab-input > li:first-child > a"),
    );
    expect(Array.from(links[1]!.classList).sort()).toEqual(
      catalogClasses("page_navbar", "ul.shiny-tab-input > li:nth-child(2) > a"),
    );

    expect(links[0]!.classList.contains("active")).toBe(true);
    expect(links[1]!.classList.contains("active")).toBe(false);
  });

  it("carries the data-value Shiny reports as input$<id>", () => {
    const { container } = render(<NavbarTabStrip id="nav" panels={panels} />);
    const values = Array.from(container.querySelectorAll("ul.shiny-tab-input > li > a")).map((a) =>
      a.getAttribute("data-value"),
    );
    expect(values).toEqual(["Browse", "Overview"]);
  });

  it("renders navbarMenu()'s dropdown shape", () => {
    const { container } = render(
      <NavbarTabStrip
        id="nav"
        panels={[
          { value: "Review", label: "Review" },
          { label: "Docs", dropdown: [{ value: "Guide", label: "Guide" }] },
        ]}
      />,
    );
    const toggle = container.querySelector("li.dropdown > a");
    expect(shapeOf(toggle)).toEqual(
      catalogShape("page_navbar_dropdown", "li.dropdown > a.dropdown-toggle"),
    );
    const item = container.querySelector("ul.dropdown-menu li > a");
    expect(Array.from(item!.classList).sort()).toEqual(
      catalogClasses("page_navbar_dropdown", "ul.dropdown-menu li > a"),
    );
  });

  it("renders nav_panel(icon = icon(...))'s <i> shape", () => {
    const { container } = render(
      <NavbarTabStrip
        id="nav"
        panels={[
          { value: "Explorer", label: "Explorer", icon: "fa-chart-column" },
          { value: "About", label: "About" },
        ]}
      />,
    );
    expect(shapeOf(container.querySelector("li i"))).toEqual(
      catalogShape("page_navbar_icon", "ul.shiny-tab-input > li:first-child i"),
    );
  });
});

describeCatalog("r", "NavSpacer and NavItem", () => {
  it("NavSpacer renders bslib::nav_spacer()'s own class", () => {
    const { container } = render(<NavSpacer />);
    expect(Array.from(container.firstElementChild!.classList).sort()).toEqual(
      catalogClasses("page_navbar", ".bslib-nav-spacer"),
    );
  });

  it("NavItem renders bslib::nav_item()'s own <li> classes", () => {
    const { container } = render(
      <ul>
        <NavItem>
          <span>x</span>
        </NavItem>
      </ul>,
    );
    expect(Array.from(container.querySelector("li")!.classList).sort()).toEqual(
      catalogClasses("page_navbar", "li.bslib-nav-item"),
    );
  });
});

describeCatalog("r", "TabPane", () => {
  it("renders a plain (non-fillable) pane matching page_navbar_not_fillable", () => {
    const shape = renderShape(
      <TabPane navId="nav" value="Overview" active>
        x
      </TabPane>,
      ".tab-pane",
    );
    expect(shape).toEqual(catalogShape("page_navbar_not_fillable", ".tab-pane.active"));
  });

  it("renders a fillable pane's classes matching a fillable page_navbar", () => {
    // catalogClasses, not catalogShape: this sample's pane also
    // carries a data-icon-class attribute from its own nav_panel(icon=),
    // which TabPane has no equivalent prop for and does not need one -
    // only the class list is compared here for that reason.
    const { container } = render(
      <TabPane navId="nav" value="Explorer" active fillable>
        x
      </TabPane>,
    );
    expect(Array.from(container.querySelector(".tab-pane")!.classList).sort()).toEqual(
      catalogClasses("page_navbar_icon", ".tab-pane.active"),
    );
  });
});

describeCatalog("r", "Card", () => {
  it("renders bslib::card(full_screen = TRUE)'s own classes and attrs", () => {
    const shape = renderShape(
      <Card fullScreen>
        <CardHeader>Title</CardHeader>
        <CardBody>Body</CardBody>
      </Card>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("card_full_screen", ".card"));
  });

  it("renders card_header and card_body classes", () => {
    const { container } = render(
      <Card>
        <CardHeader>Title</CardHeader>
        <CardBody>Body</CardBody>
      </Card>,
    );
    expect(Array.from(container.querySelector(".card-header")!.classList).sort()).toEqual(
      catalogClasses("card_full_screen", ".card-header"),
    );
    expect(shapeOf(container.querySelector(".card-body"))).toEqual(
      catalogShape("card_full_screen", ".card-body"),
    );
  });

  it("renders card_footer()'s own class", () => {
    const { container } = render(
      <Card>
        <CardHeader>Title</CardHeader>
        <CardBody>Body</CardBody>
        <CardFooter>Footer text</CardFooter>
      </Card>,
    );
    expect(Array.from(container.querySelector(".card-footer")!.classList).sort()).toEqual(
      catalogClasses("card_footer", ".card-footer"),
    );
  });

  it("renders bare (non-CardBody) children the same as card_bare_children", () => {
    const shape = renderShape(
      <Card>
        <CardHeader>Current selection</CardHeader>
        <TextOutput id="count" />
        <VerbatimTextOutput id="selected" />
      </Card>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("card_bare_children", ".card"));
  });

  it("card(id = ...) adds bslib-card-input and sets the id directly", () => {
    const shape = renderShape(
      <Card id="summary_card">
        <CardHeader>Summary</CardHeader>
        <CardBody>Body</CardBody>
      </Card>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("card_id", ".card"));
  });

  it("card(height = ...) sets an inline height style, no auto id", () => {
    const shape = renderShape(
      <Card height="400px">
        <CardHeader>Fixed height</CardHeader>
        <CardBody>Body</CardBody>
      </Card>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("card_height", ".card"));
  });

  it("card(fill = FALSE) drops html-fill-item but keeps html-fill-container", () => {
    const shape = renderShape(
      <Card fill={false}>
        <CardHeader>No fill</CardHeader>
        <CardBody>Body</CardBody>
      </Card>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("card_no_fill", ".card"));
  });
});

describeCatalog("r", "ValueBox", () => {
  it("renders bslib::value_box()'s own card/value-box shape", () => {
    const shape = renderShape(
      <ValueBox title="Genes used" theme="primary">
        <TextOutput id="ngenes_alone" className="value-box-value" />
      </ValueBox>,
      ".card",
    );
    expect(shape).toEqual(catalogShape("value_box", ".card"));
  });

  it("renders the value-box-area wrapper classes", () => {
    const { container } = render(
      <ValueBox title="PC1 variance">
        <TextOutput id="pc1" className="value-box-value" />
      </ValueBox>,
    );
    expect(Array.from(container.querySelector(".value-box-area")!.classList).sort()).toEqual(
      catalogClasses("value_box", ".value-box-area"),
    );
  });
});

describeCatalog("r", "LayoutColumns", () => {
  // layout_columns() renders a custom element, not a div, and the
  // col-widths-sm attribute is what actually drives the grid.
  it("renders bslib::layout_columns()'s own element, classes and col widths (fill = FALSE)", () => {
    const shape = renderShape(
      <LayoutColumns colWidths={[4, 4, 4]} fill={false}>
        <div>a</div>
        <div>b</div>
        <div>c</div>
      </LayoutColumns>,
      "bslib-layout-columns",
    );
    expect(shape).toEqual(catalogShape("layout_columns_value_box", "bslib-layout-columns"));
  });

  it("adds html-fill-item when fill = TRUE (the R default)", () => {
    const { container } = render(
      <LayoutColumns colWidths={[7, 5]}>
        <div>a</div>
        <div>b</div>
      </LayoutColumns>,
    );
    expect(Array.from(container.firstElementChild!.classList).sort()).toEqual(
      catalogClasses("layout_columns_fill", "bslib-layout-columns"),
    );
  });

  it("wraps each child the way bslib does", () => {
    const { container } = render(
      <LayoutColumns colWidths={[4, 4, 4]} fill={false}>
        <div>a</div>
      </LayoutColumns>,
    );
    expect(Array.from(container.querySelector(".bslib-grid-item")!.classList).sort()).toEqual(
      catalogClasses("layout_columns_value_box", ".bslib-grid-item"),
    );
  });

  it("wraps a single, non-array child the same way (layout_columns_single_child)", () => {
    const { container } = render(
      <LayoutColumns colWidths={[12]}>
        <div>Only</div>
      </LayoutColumns>,
    );
    const items = container.querySelectorAll(".bslib-grid-item");
    expect(items).toHaveLength(1);
    expect(Array.from(items[0]!.classList).sort()).toEqual(
      catalogClasses("layout_columns_single_child", ".bslib-grid-item"),
    );
  });
});

describeCatalog("r", "Tooltip", () => {
  it("renders bslib::tooltip()'s own element and attrs", () => {
    const shape = renderShape(
      <Tooltip text="Extra detail on hover">
        <i className="fas fa-circle-info" role="presentation" aria-label="circle-info icon" />
      </Tooltip>,
      "bslib-tooltip",
    );
    expect(shape).toEqual(catalogShape("tooltip", "bslib-tooltip"));
  });
});

describeCatalog("r", "LayoutSidebar", () => {
  it("renders a plain layout_sidebar()+sidebar(title=) shape (no id, no border)", () => {
    const shape = renderShape(
      <LayoutSidebar title="Filters" sidebarWidth={260} sidebar={null}>
        <div>main</div>
      </LayoutSidebar>,
      ".bslib-sidebar-layout",
    );
    expect(shape).toEqual(catalogShape("sidebar_layout_titled", ".bslib-sidebar-layout"));
  });

  it("renders a right, closed sidebar with a real id as a bound input", () => {
    const shape = renderShape(
      <LayoutSidebar
        title="Selected study"
        position="right"
        sidebarWidth={360}
        open="closed"
        id="details_pane"
        sidebar={null}
      >
        <div>main</div>
      </LayoutSidebar>,
      ".bslib-sidebar-layout",
    );
    expect(shape).toEqual(catalogShape("sidebar_layout_right_closed", ".bslib-sidebar-layout"));

    const { container } = render(
      <LayoutSidebar
        title="Selected study"
        position="right"
        sidebarWidth={360}
        open="closed"
        id="details_pane"
        sidebar={null}
      >
        <div>main</div>
      </LayoutSidebar>,
    );
    expect(shapeOf(container.querySelector("aside"))).toEqual(
      catalogShape("sidebar_layout_right_closed", "aside"),
    );
  });

  it("sidebar(class = ...) lands on the <aside>, not the layout div", () => {
    const { container } = render(
      <LayoutSidebar sidebarWidth={420} sidebarClassName="my-sidebar" sidebar={<div>a</div>}>
        <div>main</div>
      </LayoutSidebar>,
    );
    expect(Array.from(container.querySelector("aside")!.classList).sort()).toEqual(
      catalogClasses("sidebar_custom_class", "aside"),
    );
    expect(shapeOf(container.querySelector(".bslib-sidebar-layout"))).toEqual(
      catalogShape("sidebar_custom_class", ".bslib-sidebar-layout"),
    );
  });

  it("sidebar(gap=, padding=) sets an inline style on .sidebar-content", () => {
    // Not compared against the "sidebar_layout_gap_padding" catalog sample:
    // that sample passes gap/padding to layout_sidebar() itself (styling
    // .main, the content AREA's own spacing), a different R parameter from
    // sidebar(gap=, padding=) (styling .sidebar-content, the side panel's
    // own spacing) that this component's gap/padding props model - see
    // this component's own prop doc comments.
    const { container } = render(
      <LayoutSidebar sidebarWidth={280} gap="1rem" padding="1rem" sidebar="Filters">
        <div>main</div>
      </LayoutSidebar>,
    );
    expect(shapeOf(container.querySelector(".sidebar-content"))?.style).toEqual([
      "gap:1rem",
      "padding:1rem",
    ]);
  });
});

describeCatalog("r", "PageFillable, PageSidebar and PageNavbar", () => {
  // Each page component sets <body>'s classes and inline style the way the
  // matching bslib page function does, and injects the same
  // html { height: 100% } rule into <head>.
  it("PageFillable sets page_fillable()'s <body> classes and style", () => {
    render(
      <PageFillable padding={8} gap={4}>
        {"hi"}
      </PageFillable>,
    );
    expect(shapeOf(document.body)).toEqual(catalogShape("page_fillable", "body"));
  });

  it("PageFillable with no padding or gap leaves <body> unstyled, as page_fillable() does", () => {
    render(<PageFillable>{"hi"}</PageFillable>);
    expect(shapeOf(document.body)).toEqual(catalogShape("page_fillable_default", "body"));
    expect(document.body.getAttribute("style")).toBeNull();
  });

  it("PageFillable sets only the one it is given", () => {
    render(<PageFillable padding={8}>{"hi"}</PageFillable>);
    expect(document.body.style.padding).toBe("8px");
    expect(document.body.style.gap).toBe("");
  });

  it("PageSidebar sets page_sidebar()'s <body> classes and style", () => {
    render(
      <PageSidebar title="Demo" sidebar={<div />}>
        <div />
      </PageSidebar>,
    );
    expect(shapeOf(document.body)).toEqual(catalogShape("sidebar_layout", "body"));
  });

  it("a non-fillable PageNavbar adds no html { height: 100% }, like page_navbar()", () => {
    render(
      <PageNavbar
        title="Demo"
        fillable={false}
        tabStrip={<NavbarTabStrip id="nav" panels={panels} />}
      >
        {null}
      </PageNavbar>,
    );
    expect(sample("page_navbar_not_fillable", "r").head_inline_css).toEqual([]);
    expect(document.getElementById("bslib-html-height")).toBeNull();
  });

  it("PageNavbar sets page_navbar()'s <body> classes for each page shape", () => {
    const tabStrip = <NavbarTabStrip id="nav" panels={panels} />;
    const cases: Array<[string, ReactElement]> = [
      [
        "page_navbar",
        <PageNavbar key="a" title="Demo" tabStrip={tabStrip}>
          {null}
        </PageNavbar>,
      ],
      [
        "page_navbar_not_fillable",
        <PageNavbar key="b" title="Demo" fillable={false} tabStrip={tabStrip}>
          {null}
        </PageNavbar>,
      ],
      [
        "page_navbar_sidebar",
        <PageNavbar key="c" title="Demo" tabStrip={tabStrip} sidebar={<div />}>
          {null}
        </PageNavbar>,
      ],
    ];
    for (const [name, ui] of cases) {
      const { unmount } = render(ui);
      expect(shapeOf(document.body), name).toEqual(catalogShape(name, "body"));
      unmount();
    }
  });

  it("PageFillable injects the same html{height:100%} style bslib's page_fillable() does", () => {
    render(<PageFillable>{"hi"}</PageFillable>);
    const styleTag = document.getElementById("bslib-html-height");
    expect(styleTag?.textContent).toEqual(sampleHeadCss("page_fillable"));
  });

  it("PageSidebar's own sidebar layout matches page_sidebar()'s shape", () => {
    const { container } = render(
      <PageSidebar title="Demo" sidebar={<div />} sidebarWidth={290}>
        <div />
      </PageSidebar>,
    );
    expect(shapeOf(container.querySelector(".bslib-sidebar-layout"))).toEqual(
      catalogShape("sidebar_layout", ".bslib-sidebar-layout"),
    );
    expect(shapeOf(container.querySelector("aside"))).toEqual(
      catalogShape("sidebar_layout", "aside"),
    );
  });

  it("PageNavbar's nav shell matches page_navbar()'s bg/theme/brand shape", () => {
    const shape = renderShape(
      <PageNavbar
        title="Demo"
        bg="#447099"
        navbarTheme="dark"
        tabStrip={<NavbarTabStrip id="nav" panels={panels} />}
      >
        <TabPane navId="nav" value="Browse" active>
          x
        </TabPane>
        <TabPane navId="nav" value="Overview">
          y
        </TabPane>
      </PageNavbar>,
      "nav",
    );
    expect(shape).toEqual(catalogShape("page_navbar", "nav"));
  });

  it("PageNavbar's tab-content area drops fill classes when fillable = FALSE", () => {
    const { container } = render(
      <PageNavbar
        title="Demo"
        fillable={false}
        tabStrip={<NavbarTabStrip id="nav" panels={panels} />}
      >
        <TabPane navId="nav" value="Browse" active>
          x
        </TabPane>
        <TabPane navId="nav" value="Overview">
          y
        </TabPane>
      </PageNavbar>,
    );
    expect(Array.from(container.querySelector(".tab-content")!.classList).sort()).toEqual(
      catalogClasses("page_navbar_not_fillable", ".tab-content"),
    );
    expect(Array.from(container.querySelector(".container-fluid")!.classList).sort()).toEqual(
      catalogClasses("page_navbar_not_fillable", ".container-fluid"),
    );
  });

  it("PageNavbar wraps a page-wide sidebar with no border, matching page_navbar(sidebar=)", () => {
    const shape = renderShape(
      <PageNavbar
        title="Demo"
        tabStrip={<NavbarTabStrip id="nav" panels={[{ value: "Build", label: "Build" }]} />}
        sidebar={<div>chat</div>}
        sidebarId="dock"
        sidebarWidth={600}
        sidebarOpen="closed"
      >
        <TabPane navId="nav" value="Build" active>
          build content
        </TabPane>
      </PageNavbar>,
      ".bslib-sidebar-layout",
    );
    expect(shape).toEqual(catalogShape("page_navbar_sidebar", ".bslib-sidebar-layout"));
  });
});

describeCatalog("r", "Output components", () => {
  it("PlotOutput matches shiny::plotOutput()", () => {
    expect(renderShape(<PlotOutput id="x" />, "#x")).toEqual(catalogShape("plotOutput", "#x"));
  });

  it("PlotOutput with click matches shiny::plotOutput(click=)", () => {
    const shape = renderShape(<PlotOutput id="x" height="560px" click="x_click" />, "#x");
    expect(shape).toEqual(catalogShape("plotOutput_click", "#x"));
  });

  it("TextOutput matches shiny::textOutput()", () => {
    expect(renderShape(<TextOutput id="x" />, "#x")).toEqual(catalogShape("textOutput", "#x"));
  });

  it("VerbatimTextOutput matches shiny::verbatimTextOutput()", () => {
    expect(renderShape(<VerbatimTextOutput id="x" />, "#x")).toEqual(
      catalogShape("verbatimTextOutput", "#x"),
    );
  });

  it("DTOutput matches DT::DTOutput(fill = TRUE)", () => {
    expect(renderShape(<DTOutput id="x" />, "#x")).toEqual(catalogShape("DTOutput", "#x"));
  });

  it("DTOutput with fill = false matches DT::DTOutput(fill = FALSE)", () => {
    expect(renderShape(<DTOutput id="x" fill={false} />, "#x")).toEqual(
      catalogShape("DTOutput_no_fill", "#x"),
    );
  });

  it("ReactableOutput matches reactable::reactableOutput()", () => {
    expect(renderShape(<ReactableOutput id="x" />, "#x")).toEqual(
      catalogShape("reactableOutput", "#x"),
    );
  });

  it("WidgetOutput matches a generic htmlwidget output", () => {
    const shape = renderShape(<WidgetOutput id="x" widgetClass="foo" />, "#x");
    expect(shape).toEqual(catalogShape("htmlwidget_output", "#x"));
  });

  it("UiOutput matches shiny::uiOutput()", () => {
    expect(renderShape(<UiOutput id="x" />, "#x")).toEqual(catalogShape("uiOutput", "#x"));
  });

  it("UiOutput with fill matches shiny::uiOutput(fill = TRUE)", () => {
    expect(renderShape(<UiOutput id="x" fill />, "#x")).toEqual(
      catalogShape("uiOutput_fill", "#x"),
    );
  });

  it("UiOutput with inline renders a <span>, matching uiOutput(inline = TRUE)", () => {
    const shape = renderShape(<UiOutput id="chip" inline />, "#chip");
    expect(shape).toEqual(catalogShape("uiOutput_inline", "#chip"));
  });
});

describeCatalog("r", "HelpText", () => {
  it("matches shiny::helpText()'s own span", () => {
    const shape = renderShape(<HelpText>Some help text here.</HelpText>, ".help-block");
    expect(shape).toEqual(catalogShape("helpText_hr", ".help-block"));
  });
});

// HostedInput has no markup of its own to pin against the catalog (see
// docs/markup.md): the widget's HTML comes from the parent app's own R call at
// runtime, not from this component. What a fixed assertion CAN check is the
// wrapper shape every hosted widget depends on: a shiny-html-output div
// (or span/etc via ShinyOutput's own tagName) carrying the id the parent's
// own `output$<id>_ui <- renderUI(...)` answers, with namespacing handled
// through Module the same way every other hosted piece in this kit is.
describe("HostedInput", () => {
  it("renders a shiny-html-output wrapper with the given id", () => {
    const { container } = render(<HostedInput id="lfc_ui" />);
    const el = container.querySelector("#lfc_ui");
    expect(el).not.toBeNull();
    expect(el!.classList.contains("shiny-html-output")).toBe(true);
  });

  it("namespaces its id inside a Module, the same way a hosted output does", () => {
    const { container } = render(
      <Module namespace="mod">
        <HostedInput id="lfc_ui" />
      </Module>,
    );
    expect(container.querySelector("#mod-lfc_ui")).not.toBeNull();
    expect(container.querySelector("#lfc_ui")).toBeNull();
  });
});

describe("Outputs inside a Module", () => {
  it("namespace the element id and the plot's click input id", () => {
    const { container } = render(
      <Module namespace="volcano">
        <PlotOutput id="plot" click="click" />
      </Module>,
    );
    const el = container.querySelector("#volcano-plot");
    expect(el).not.toBeNull();
    expect(el!.getAttribute("data-click-id")).toBe("volcano-click");
  });

  it("namespace reactable's data attribute the same way as its id", () => {
    const { container } = render(
      <Module namespace="m">
        <ReactableOutput id="tbl" />
      </Module>,
    );
    expect(container.querySelector("#m-tbl")!.getAttribute("data-reactable-output")).toBe("m-tbl");
  });
});

describe("Card, NavbarTabStrip and PageNavbar details", () => {
  it("Card namespaces its id inside a Module, since the id makes it an input", () => {
    const { container } = render(
      <Module namespace="m">
        <Card id="c">
          <CardBody>x</CardBody>
        </Card>
      </Module>,
    );
    expect(container.querySelector(".card")!.id).toBe("m-c");
  });

  it("NavbarTabStrip shows a dropdown toggle's and item's icons, as nav_menu() does", () => {
    // bslib renders <i class="fas fa-book fa-fw"> before "Docs" on the toggle,
    // and shiny::icon("compass") picks the regular style: "far fa-compass".
    const { container } = render(
      <NavbarTabStrip
        id="nav"
        panels={[
          {
            label: "Docs",
            icon: "fa-book",
            dropdown: [{ value: "g", label: "Guide", icon: "far fa-compass" }],
          },
        ]}
      />,
    );
    const toggleIcon = container.querySelector(".dropdown-toggle > i")!;
    expect(Array.from(toggleIcon.classList).sort()).toEqual(["fa-book", "fa-fw", "fas"]);
    const itemIcon = container.querySelector(".dropdown-item > i")!;
    expect(Array.from(itemIcon.classList).sort()).toEqual(["fa-compass", "fa-fw", "far"]);
    expect(itemIcon.getAttribute("aria-label")).toBe("compass icon");
  });

  it("PageNavbar clears its background when bg goes away", () => {
    const strip = <NavbarTabStrip id="nav" panels={panels} />;
    const { container, rerender } = render(
      <PageNavbar title="Demo" bg="#123456" tabStrip={strip}>
        {null}
      </PageNavbar>,
    );
    const nav = container.querySelector("nav")!;
    expect(nav.style.getPropertyValue("background-color")).not.toBe("");
    rerender(
      <PageNavbar title="Demo" tabStrip={strip}>
        {null}
      </PageNavbar>,
    );
    expect(nav.style.getPropertyValue("background-color")).toBe("");
  });
});

describe("TabPane inside PageNavbar", () => {
  it("defaults fillable to the PageNavbar's own setting", () => {
    for (const fillable of [true, false]) {
      const { container, unmount } = render(
        <PageNavbar
          title="Demo"
          fillable={fillable}
          tabStrip={<NavbarTabStrip id="nav" panels={panels} />}
        >
          <TabPane navId="nav" value="Browse" active>
            x
          </TabPane>
        </PageNavbar>,
      );
      const pane = container.querySelector(".tab-pane")!;
      expect(pane.classList.contains("html-fill-item")).toBe(fillable);
      unmount();
    }
  });
});

describe("NavbarTabStrip and TabPane with a Module", () => {
  it("point each tab's href at its pane's id when both sit inside one", () => {
    const { container } = render(
      <Module namespace="mod">
        <NavbarTabStrip id="nav" panels={[{ value: "One", label: "One" }]} />
        <TabPane navId="nav" value="One" active>
          x
        </TabPane>
      </Module>,
    );
    const href = container.querySelector("a.nav-link")!.getAttribute("href");
    const paneId = container.querySelector(".tab-pane")!.id;
    expect(href).toBe(`#${paneId}`);
    expect(container.querySelector("ul.shiny-tab-input")!.id).toBe("mod-nav");
  });

  it("still match when only the pane sits inside a Module", () => {
    const { container } = render(
      <>
        <NavbarTabStrip id="nav" panels={[{ value: "One", label: "One" }]} />
        <Module namespace="explorer">
          <TabPane navId="nav" value="One" active>
            x
          </TabPane>
        </Module>
      </>,
    );
    const href = container.querySelector("a.nav-link")!.getAttribute("href");
    expect(href).toBe(`#${container.querySelector(".tab-pane")!.id}`);
  });
});

/** The head_inline_css entry every page_*() sample carries: bslib's own
 *  `tags$head(tags$style("html { height: 100%; }"))`, injected by
 *  usePageBody() the same way. Reads it off any "page" kind sample instead
 *  of hard-coding the string twice. */
function sampleHeadCss(name: string): string | undefined {
  return sample(name, "r").head_inline_css[0];
}
