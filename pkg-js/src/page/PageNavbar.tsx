import { useLayoutEffect, useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { LayoutSidebar } from "../layout/Sidebar";
import { NavbarFillableContext } from "../nav/navbarFillable";
import { usePageBody } from "./usePageBody";

type Props = {
  /** page_navbar(title = ...). Plain text, or any node (an image beside a
   *  wordmark, say), rendered inside .navbar-brand. */
  title: ReactNode;
  /** navbar_options(bg = ...): a fixed navbar color. */
  bg?: string;
  /** navbar_options(theme = "dark" | "light"). Omit when the parent passes
   *  no navbar_options(): bslib then renders data-bs-theme="auto" and no
   *  navbar-inverse class. */
  navbarTheme?: "dark" | "light";
  tabStrip: ReactNode;
  footer?: ReactNode;
  /** page_navbar(sidebar = sidebar(...)): one sidebar beside every tab. It
   *  wraps the tab content (and the footer) in a sidebar layout and adds
   *  has-page-sidebar to <body>. */
  sidebar?: ReactNode;
  /** sidebar(id = ...): makes that sidebar a Shiny input. */
  sidebarId?: string;
  sidebarWidth?: number;
  /** sidebar(open = ...). bslib uses the same value for mobile, and the
   *  sidebar stays collapsible on mobile. */
  sidebarOpen?: "open" | "closed";
  /** page_navbar(fillable = TRUE/FALSE). FALSE drops the fill classes from
   *  the content wrappers and, with no `sidebar`, gives the bare
   *  "bslib-page-navbar" <body> with no html { height: 100% }. Each TabPane defaults to this value; see TabPane for
   *  page_navbar(fillable = c("Browse")). */
  fillable?: boolean;
  children: ReactNode;
};

const COLLAPSE_ID = "bslib-navbar-collapse";

/**
 * bslib::page_navbar(). Markup pinned against the `page_navbar`,
 * `page_navbar_sidebar` and `page_navbar_not_fillable` catalog samples.
 * Sets the <body> classes page_navbar() would (page_react() leaves <body>
 * bare), then renders the navbar shell and the tab-content area. Callers
 * pass the tab strip (NavbarTabStrip) and the panes (TabPane).
 *
 * `bg` is set with style.setProperty(..., "important"), matching the
 * !important navbar_options(bg = ) renders: React's style prop silently
 * drops "!important".
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
  // page_navbar() picks a bare page only when fillable is FALSE and there is
  // no sidebar (`if (isFALSE(fillable) && is.null(sidebar)) page else
  // page_fillable(padding = 0, gap = 0)`), so a sidebar always gets the
  // fillable <body>. The panes still follow `fillable` itself.
  const fillablePage = fillable || Boolean(sidebar);
  usePageBody(
    fillablePage
      ? cx(
          "bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container bslib-page-navbar",
          Boolean(sidebar) && "has-page-sidebar",
        )
      : "bslib-page-navbar",
    fillablePage ? { padding: "0px", gap: "0px" } : {},
    fillablePage,
  );

  const navRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    if (bg) {
      navRef.current?.style.setProperty("background-color", bg, "important");
    }
  }, [bg]);

  const tabContent = (
    <div className={cx("tab-content", fillable && "html-fill-item html-fill-container")}>
      <NavbarFillableContext.Provider value={fillable}>{children}</NavbarFillableContext.Provider>
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
