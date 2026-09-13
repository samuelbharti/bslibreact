import { useId, useLayoutEffect, useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { useNs } from "../module/Module";
import { useBoundScope } from "../bind/useBoundScope";

type Props = {
  sidebar: ReactNode;
  sidebarWidth?: number;
  /** sidebar(title = ...): renders a <header class="sidebar-title">. */
  title?: string;
  /** sidebar(position = ...). Default "left", page_sidebar()'s own shape. */
  position?: "left" | "right";
  /** sidebar(open = ...). Default "open", page_sidebar()'s own shape. */
  open?: "open" | "closed";
  /**
   * sidebar(id = ...): makes the aside a real Shiny input (adds
   * bslib-sidebar-input, and toggle_sidebar()/input$<id> work server-side).
   * Omit for a plain, non-controllable sidebar (page_sidebar()'s own
   * shape, an auto id, no input binding).
   */
  id?: string;
  /**
   * The two mobile/desktop collapse knobs page_sidebar() vs a plain
   * layout_sidebar() set differently by default - page_sidebar() locks
   * its sidebar always-open on mobile since it is primary navigation; a
   * secondary in-page sidebar (Browse's filters, say) collapses on
   * mobile like desktop. The default here (true) matches a plain
   * layout_sidebar()+sidebar() (confirmed against the "sidebar_layout_titled",
   * "sidebar_layout_right_closed", "sidebar_layout_gap_padding", and
   * "sidebar_custom_class" catalog samples, all data-collapsible-mobile="true"
   * with no explicit collapsible argument in the call); PageSidebar passes
   * false explicitly to reproduce page_sidebar()'s own locked-open shape
   * (confirmed against "sidebar_layout", data-collapsible-mobile="false").
   * An earlier version of this component defaulted to false here, correct
   * for its first caller (PageSidebar) but wrong for a direct
   * layout_sidebar()+sidebar() use - a gap this component's own comment
   * used to flag directly ("since that was this component's first and,
   * until now, only caller").
   */
  collapsibleMobile?: boolean;
  /**
   * data-open-mobile. Defaults to "closed", bslib's own default for a
   * plain layout_sidebar()+sidebar() with no explicit open argument
   * (confirmed against the same four standalone catalog samples above:
   * every one shows data-open-desktop="open" data-open-mobile="closed",
   * even though `open` itself was never passed - mobile does NOT inherit
   * desktop's own "open" default). An explicit open="open"/"closed" on the
   * `open` prop mirrors to both desktop and mobile instead, confirmed by
   * "sidebar_layout_right_closed" (open="closed" produces both
   * data-open-desktop and data-open-mobile "closed") and, from R directly,
   * `page_navbar(sidebar = sidebar(open = "open"))`
   * (data-open-mobile="open", not "always" or "closed") - callers that
   * need that mirroring (PageNavbar's own sidebarOpen prop) pass
   * `openMobile` explicitly rather than relying on this default.
   * PageSidebar passes "always" explicitly, its own locked-open shape
   * (confirmed against "sidebar_layout").
   */
  openMobile?: "always" | "open" | "closed";
  /**
   * layout_sidebar(border = ...). bslib's own default is NULL, which
   * renders no attribute at all (the theme's own border style applies) -
   * confirmed against the four standalone catalog samples above, none of
   * which carries data-bslib-sidebar-border. page_sidebar() and
   * page_navbar(sidebar = ...)'s own app-wide sidebar both pass FALSE
   * explicitly (confirmed against "sidebar_layout" and
   * "page_navbar_sidebar", both data-bslib-sidebar-border="false"); leave
   * this undefined for a plain layout_sidebar()+sidebar() call.
   */
  border?: boolean;
  /** layout_sidebar(border_radius = ...), the same NULL-vs-explicit shape
   *  as `border`, confirmed the same way. */
  borderRadius?: boolean;
  /**
   * sidebar(class = "..."): an extra class on the <aside> itself (a
   * caller-side CSS hook, e.g. gene-list-builder's own "glb-build-sidebar"
   * padding override), not on the surrounding layout div. Confirmed by
   * rendering `sidebar(class = "x", ...)` from R: the class lands on
   * `<aside class="sidebar x">`.
   */
  sidebarClassName?: string;
  /** sidebar(gap = ...): an inline `gap` CSS value on `.sidebar-content`
   *  (its own flex layout), tighter than the default bslib-gap-spacing.
   *  Confirmed by rendering `sidebar(gap = "0.4rem", ...)` from R:
   *  `style="gap:0.4rem;..."` on the content div, not the <aside> itself.
   *  tahoe-explorer's drugs/cell_lines/coverage filter sidebars all set
   *  this alongside `padding`. */
  gap?: string;
  /** sidebar(padding = ...): the matching inline `padding` value on the
   *  same `.sidebar-content` div, confirmed the same way. */
  padding?: string;
  children: ReactNode;
};

/**
 * bslib::layout_sidebar() + sidebar(). Markup pinned against the
 * "sidebar_layout_titled", "sidebar_layout_right_closed",
 * "sidebar_layout_gap_padding", and "sidebar_custom_class" catalog samples
 * for a plain, standalone call (bslib 0.12.0); PageSidebar and PageNavbar
 * each pin their OWN page-level defaults (collapsibleMobile, openMobile,
 * border, borderRadius) against "sidebar_layout" and "page_navbar_sidebar"
 * respectively, by passing them explicitly rather than relying on this
 * component's own defaults. The aside starts `hidden` in the
 * server-rendered version too: bslib.Sidebar.initCollapsibleAll() (called
 * from an effect here, the same script tag bslib itself emits) un-hides it
 * in the correct open/collapsed state for the viewport.
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
  // useNs is a hook, so it always runs; the result is only used when id
  // is actually given, matching the rule every other hosted piece follows.
  const fullId = useNs(id ?? "");
  const asideId = id ? fullId : `bslib-sidebar-${rawId}`;
  const asideRef = useRef<HTMLElement>(null);
  const layoutDivRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    window.bslib?.Sidebar?.initCollapsibleAll();
  }, []);

  // A sidebar with an id is bslib's own input (toggle_sidebar() targets it
  // server-side), so it needs binding - through useBoundScope, not a plain
  // useEffect calling Shiny.initializeInputs()/bindAll() directly, because
  // this <aside> can hold a hosted output (a HostedInput, a PlotOutput, ...)
  // in its `sidebar` content, same as `children` can in the surrounding
  // <main>. See useBoundScope's own file comment for why calling
  // Shiny.bindAll() on a scope that, in the same commit, also contains a
  // freshly mounted hosted output produces Shiny's "Duplicate output IDs"
  // warning, and why the fix is to withhold that content rather than make
  // the manual call itself smarter.
  //
  // Scope is the outer layout div (layoutDivRef), an ancestor of <aside>,
  // not <aside> itself: bslib-sidebar-input lives on <aside>, and every
  // Shiny binding's find(scope) is descendants-only, so scope has to be
  // something ABOVE the element being found, exactly the way the old
  // effect already (correctly) used el.parentElement here. Unbinding on
  // cleanup still targets the <aside> itself (asideRef, matching the old
  // Shiny.unbindAll(el, true)), since that is the one element this hook
  // bound, not the whole layout div.
  //
  // enabled = Boolean(id): with no id, useBoundScope returns true at once
  // and does nothing else, matching the old code's plain `if (!id) return`
  // early exit - a sidebar with no id is not a Shiny input, so there is
  // nothing to bind or wait for, and `sidebar`/`children` render straight
  // away.
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
