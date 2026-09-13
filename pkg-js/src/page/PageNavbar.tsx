import { useLayoutEffect, useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { LayoutSidebar } from "../layout/Sidebar";
import { usePageBody } from "./usePageBody";

type Props = {
  /**
   * navbarPage(title = ...) / page_navbar(title = ...). Usually plain text,
   * but the parent's own title can be a tagList (genescout's mascot image +
   * wordmark span, `.navbar-brand` wrapping both as siblings) - a plain
   * string still renders the same way, so this stays a superset, not a
   * breaking change for any existing caller.
   */
  title: ReactNode;
  /** navbar_options(bg = ...): a fixed navbar color, independent of dark mode. */
  bg?: string;
  /**
   * navbar_options(theme = "dark" | "light"). Omit when the parent's own
   * page_navbar() call passes no navbar_options() at all: bslib then
   * renders `data-bs-theme="auto"` and drops the "navbar-inverse" class
   * entirely (confirmed by dumping a bare page_navbar() from R, no bg, no
   * navbar_options - `class="navbar navbar-default navbar-static-top"`,
   * no "navbar-inverse"). Passing "dark" or "light" here reproduces an
   * explicit navbar_options(theme = ...) call instead, "navbar-inverse"
   * class included, matching recount-explorer's own coffee-dark navbar.
   */
  navbarTheme?: "dark" | "light";
  tabStrip: ReactNode;
  footer?: ReactNode;
  /**
   * page_navbar(sidebar = bslib::sidebar(...)): an app-wide sidebar beside
   * EVERY tab's content, not one tab's own layout_sidebar(). Markup pinned
   * against a real `page_navbar(sidebar = sidebar(...))` dump: it wraps
   * the whole tab-content area (and the footer) in the same
   * bslib-sidebar-layout shape LayoutSidebar already renders for a
   * per-panel sidebar, drops the "container-fluid" class the no-sidebar
   * shape has on that wrapping div, and adds "has-page-sidebar" to
   * <body>. Confirmed the footer moves INSIDE <main>, after the
   * tab-content div, once a sidebar is present (outside it, alongside
   * tab-content, when there is none) - two different shapes, not one
   * smaller than the other.
   */
  sidebar?: ReactNode;
  /** sidebar(id = ...): required for the sidebar to be a real Shiny input
   *  (toggle_sidebar() target) - gene-list-builder's own assistant dock. */
  sidebarId?: string;
  sidebarWidth?: number;
  /**
   * sidebar(open = ...), a plain "open"/"closed" string (not bslib's
   * "desktop" default shape). Dumping `page_navbar(sidebar = sidebar(open
   * = "closed"))` from R shows this ALSO drives collapsible-mobile (always
   * true here, unlike LayoutSidebar's own page_sidebar()-shaped default)
   * and open-mobile (mirrors this value exactly, not "always"), so both
   * are set that way below rather than exposed as separate props - no
   * caller of this component has needed the "desktop" shape yet.
   */
  sidebarOpen?: "open" | "closed";
  /**
   * page_navbar(fillable = ...) as a plain boolean covering every panel
   * (the R default is TRUE). A per-panel subset is TabPane's own
   * `fillable` prop, not this one - see its docstring. Dumping
   * `page_navbar(fillable = FALSE, nav_panel(...))` from R (bslib 0.12.0)
   * next to the TRUE-default fixture shows the difference reaches past
   * TabPane: <body> drops to the bare "bslib-page-navbar" class with no
   * inline style at all, and both the sidebar-less container-fluid wrapper
   * and the inner tab-content div drop their html-fill-item/
   * html-fill-container classes too - not just each pane. variant-reviewer's
   * own page_navbar() passes `fillable = FALSE` (a long, page-scrolling
   * dashboard, not a fixed-height view), the first port to need this.
   */
  fillable?: boolean;
  children: ReactNode;
};

const COLLAPSE_ID = "bslib-navbar-collapse";

/**
 * bslib::page_navbar(). Markup pinned against the `page_navbar` catalog
 * sample (bslib 0.12.0, no sidebar), `page_navbar_sidebar`
 * (`page_navbar(sidebar = sidebar(...))`, with sidebar), and
 * `page_navbar_not_fillable` (`page_navbar(fillable = FALSE, ...)`, see the
 * `fillable` prop doc, above). page_react() renders
 * a bare <body>, so this sets the body classes a real page_navbar() page
 * would have, then renders the navbar shell (brand, collapse toggle, tab
 * strip) and the tab-content area. Callers pass the tab strip
 * (NavbarTabStrip) and each pane (TabPane) as children, since only they
 * know the app's own nav items.
 *
 * bg needs the !important a navbar_options(bg=) call renders (it overrides
 * a dark-mode toggle's own background variable), which only works set
 * through CSSStyleDeclaration.setProperty(..., "important"): React's style
 * prop assigns the plain CSS property setter instead, which silently
 * drops any "!important" text in the value.
 */
export function PageNavbar({
  title,
  bg,
  navbarTheme,
  tabStrip,
  footer,
  sidebar,
  sidebarId,
  sidebarWidth = 250,
  sidebarOpen = "open",
  fillable = true,
  children,
}: Props) {
  // bslib::page_navbar()'s own source picks the outer page shell:
  // `page_func <- if (isFALSE(fillable) && is.null(sidebar)) page else
  // function(...) page_fillable(..., padding = 0, gap = 0)` - the bare,
  // non-fillable <body> shape only applies when BOTH fillable is false AND
  // there is no sidebar. An app-wide sidebar (page_navbar(sidebar = ...))
  // always gets the fillable shell, even when every individual tab panel
  // is not fillable (tahoe-explorer's own page_navbar(fillable = FALSE,
  // sidebar = sidebar(...)) - confirmed against the real running parent
  // with peek.R: <body> carried the full fillable class list and the
  // padding:0;gap:0 inline style despite fillable = FALSE, because its
  // assistant-dock sidebar is present). TabPane's own per-panel fill
  // classing is untouched by this - bslib passes the ORIGINAL fillable
  // value into navs_bar_() unchanged, so only this outer-shell selection
  // depends on sidebar presence too.
  const fillablePage = fillable || Boolean(sidebar);
  usePageBody(
    fillablePage
      ? cx(
          "bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container bslib-page-navbar",
          Boolean(sidebar) && "has-page-sidebar",
        )
      : "bslib-page-navbar",
    fillablePage ? { padding: "0px", gap: "0px" } : {},
  );

  const navRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    if (bg) {
      navRef.current?.style.setProperty("background-color", bg, "important");
    }
  }, [bg]);

  const tabContent = (
    <div className={cx("tab-content", fillable && "html-fill-item html-fill-container")}>
      {children}
    </div>
  );

  return (
    <>
      <nav
        ref={navRef}
        className={cx("navbar navbar-default navbar-static-top", navbarTheme && "navbar-inverse")}
        role="navigation"
        data-bs-theme={navbarTheme ?? "auto"}
      >
        <div className="container-fluid">
          <div className="navbar-header">
            <button
              type="button"
              className="navbar-toggle collapsed"
              data-toggle="collapse"
              data-target={`#${COLLAPSE_ID}`}
              data-bs-toggle="collapse"
              data-bs-target={`#${COLLAPSE_ID}`}
            >
              <span className="sr-only visually-hidden">Toggle navigation</span>
              <span className="icon-bar" />
              <span className="icon-bar" />
              <span className="icon-bar" />
            </button>
            <span className="navbar-brand">{title}</span>
          </div>
          <div className="navbar-collapse collapse" id={COLLAPSE_ID}>
            {tabStrip}
          </div>
        </div>
      </nav>
      {sidebar ? (
        <div className={cx(fillable && "html-fill-item html-fill-container")}>
          <LayoutSidebar
            sidebar={sidebar}
            sidebarWidth={sidebarWidth}
            id={sidebarId}
            open={sidebarOpen}
            openMobile={sidebarOpen}
            collapsibleMobile
            // page_navbar(sidebar = ...)'s own app-wide sidebar, like
            // page_sidebar()'s, has no border (confirmed against the
            // "page_navbar_sidebar" catalog sample).
            border={false}
            borderRadius={false}
          >
            {tabContent}
            {footer}
          </LayoutSidebar>
        </div>
      ) : (
        <div className={cx("container-fluid", fillable && "html-fill-item html-fill-container")}>
          {tabContent}
          {footer}
        </div>
      )}
    </>
  );
}
