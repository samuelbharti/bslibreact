import { useId, useLayoutEffect, useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { useNs } from "../module/Module";
import { useBoundScope } from "../bind/useBoundScope";

type Props = {
  sidebar: ReactNode;
  sidebarWidth?: number;
  /** sidebar(title = ...): renders a <header class="sidebar-title">. */
  title?: string;
  /** sidebar(position = ...). */
  position?: "left" | "right";
  /** sidebar(open = ...), for desktop. */
  open?: "open" | "closed";
  /** sidebar(id = ...): makes the <aside> a Shiny input (bslib-sidebar-input),
   *  so toggle_sidebar() and input$<id> work. Omit for a plain sidebar. */
  id?: string;
  /** data-collapsible-mobile. True for a plain layout_sidebar(); PageSidebar
   *  passes false, since page_sidebar() keeps its sidebar open on mobile. */
  collapsibleMobile?: boolean;
  /** data-open-mobile. "closed" matches a plain layout_sidebar(), where
   *  mobile does not follow `open`'s default. An explicit sidebar(open =
   *  "open") sets mobile too, so pass openMobile="open" for it. PageSidebar
   *  passes "always", and PageNavbar its own `sidebarOpen`. */
  openMobile?: "always" | "open" | "closed";
  /** layout_sidebar(border = ...). Undefined renders no attribute, bslib's
   *  default; page_sidebar() and page_navbar(sidebar = ) pass false. */
  border?: boolean;
  /** layout_sidebar(border_radius = ...), the same way as `border`. */
  borderRadius?: boolean;
  /** sidebar(class = ...): an extra class on the <aside> itself. */
  sidebarClassName?: string;
  /** sidebar(gap = ...): an inline gap on .sidebar-content. */
  gap?: string;
  /** sidebar(padding = ...): an inline padding on .sidebar-content. */
  padding?: string;
  children: ReactNode;
};

/**
 * bslib::layout_sidebar() + sidebar(). Markup pinned against the
 * "sidebar_layout_titled", "sidebar_layout_right_closed" and
 * "sidebar_custom_class" catalog samples;
 * PageSidebar and PageNavbar pass their own page-level defaults explicitly.
 * The <aside> starts `hidden`, as in bslib's own markup:
 * bslib.Sidebar.initCollapsibleAll(), called from an effect here, shows it
 * in the right open or collapsed state for the viewport.
 */
export function LayoutSidebar({
  sidebar,
  sidebarWidth = 250,
  title,
  position = "left",
  open = "open",
  id,
  collapsibleMobile = true,
  openMobile = "closed",
  border,
  borderRadius,
  sidebarClassName,
  gap,
  padding,
  children,
}: Props) {
  const rawId = useId();
  // A hook, so it always runs; the result is used only when `id` is set.
  const fullId = useNs(id ?? "");
  const asideId = id ? fullId : `bslib-sidebar-${rawId}`;
  const asideRef = useRef<HTMLElement>(null);
  const layoutDivRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    window.bslib?.Sidebar?.initCollapsibleAll();
  }, []);

  // A sidebar with an id is a Shiny input, bound through useBoundScope so
  // the hosted content in `sidebar` and `children` waits for that bind (see
  // its file comment). The scope is the layout div, an ancestor of the
  // <aside>, since Shiny's find() is descendants-only. Without an id there
  // is nothing to bind and everything renders at once.
  const childrenReady = useBoundScope(asideRef, () => layoutDivRef.current, Boolean(id));

  return (
    <div
      ref={layoutDivRef}
      className={cx(
        "bslib-sidebar-layout bslib-mb-spacing html-fill-item",
        position === "right" && "sidebar-right",
        open === "closed" && "sidebar-collapsed",
      )}
      data-bslib-sidebar-border={border === undefined ? undefined : border ? "true" : "false"}
      data-bslib-sidebar-border-radius={
        borderRadius === undefined ? undefined : borderRadius ? "true" : "false"
      }
      data-bslib-sidebar-init="TRUE"
      data-collapsible-desktop="true"
      data-collapsible-mobile={collapsibleMobile ? "true" : "false"}
      data-open-desktop={open}
      data-open-mobile={openMobile}
      data-require-bs-caller="layout_sidebar()"
      data-require-bs-version="5"
      style={{ ["--_sidebar-width" as string]: `${sidebarWidth}px` }}
    >
      <div className="main bslib-gap-spacing html-fill-container">
        <main className="bslib-page-main bslib-gap-spacing html-fill-item html-fill-container">
          {childrenReady && children}
        </main>
      </div>
      <aside
        ref={asideRef}
        id={asideId}
        className={cx("sidebar", id && "bslib-sidebar-input", sidebarClassName)}
        hidden
        data-resizable=""
      >
        <div
          className="sidebar-content bslib-gap-spacing"
          style={gap !== undefined || padding !== undefined ? { gap, padding } : undefined}
        >
          {title !== undefined && <header className="sidebar-title">{title}</header>}
          {childrenReady && sidebar}
        </div>
      </aside>
      <button
        className="collapse-toggle"
        type="button"
        title="Toggle sidebar"
        aria-expanded={open === "open" ? "true" : "false"}
        aria-controls={asideId}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 16 16"
          className="bi bi-chevron-left collapse-icon"
          style={{ fill: "currentColor", verticalAlign: "-0.125em" }}
          aria-hidden="true"
          role="img"
        >
          <path
            fillRule="evenodd"
            d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"
          />
        </svg>
      </button>
    </div>
  );
}
