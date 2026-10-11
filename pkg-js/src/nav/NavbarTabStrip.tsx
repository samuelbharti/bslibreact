import { useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { useNs } from "../module/Module";
import { useBoundScope } from "../bind/useBoundScope";

export type NavPanelDef = {
  value: string;
  label: string;
  /** bslib::nav_panel(icon = icon("...")): a Font Awesome class, e.g.
   *  "fa-chart-column". Rendered with the same fa-fw (fixed width) class
   *  nav_panel()'s own icon gets, before the label. Markup pinned
   *  against a real nav_panel(icon=) dump: `fas <name> fa-fw`, no
   *  wrapping span, as a sibling of the label text inside the <a>. */
  icon?: string;
};

/**
 * shiny::navbarPage()'s navbarMenu(title, tabPanel(...), tabPanel(...)): a
 * dropdown grouping of sub-panels under one label (genescout's "Docs" menu).
 * Markup verified against a real running app's served HTML, not an
 * as.character() dump - the distinction documented above and in
 * docs/porting.md matters for navbar markup specifically. A real
 * `navbarPage(collapsible = TRUE, theme = bs_theme(...), tabPanel(...),
 * navbarMenu("Docs", tabPanel(...), tabPanel(...)))`, served through a live
 * shiny::runApp(), renders one `<li class="dropdown nav-item">` holding a
 * `.dropdown-toggle.nav-link` (a caret, no href target - it never becomes an
 * active tab itself) and its own nested `<ul class="dropdown-menu">` of
 * `.dropdown-item` links, one per sub-panel. Pinned against the
 * `page_navbar_dropdown` catalog sample (a served `bslib::page_navbar(id =
 * "nav", bslib::nav_menu(...))`, the bslib equivalent of the same shape).
 */
export type NavDropdownDef = {
  label: string;
  dropdown: readonly NavPanelDef[];
};

export type NavEntry = NavPanelDef | NavDropdownDef;

function isDropdown(entry: NavEntry): entry is NavDropdownDef {
  return "dropdown" in entry;
}

type Props = {
  id: string;
  panels: readonly NavEntry[];
  /** Extra nav items after the tabs: nav_spacer(), nav_item(...), and so on. */
  children?: ReactNode;
};

function slug(value: string) {
  return value.replace(/\s+/g, "-");
}

// Built from the raw navId on both sides (tab href and TabPane id), never
// the namespaced one: a strip and its panes then match wherever a <Module>
// sits, around both, around a pane, or nowhere. Only the <ul>'s own id,
// the Shiny input id, is namespaced.
export function tabPaneId(navId: string, value: string) {
  return `tab-${navId}-${slug(value)}`;
}

/**
 * The <ul class="nav ... shiny-tab-input"> bslib::page_navbar()/nav_panel()
 * render.
 *
 * A plain `htmltools::renderTags()` dump of this call, outside a running
 * Shiny session, is stale here: page_navbar()'s own tab markup comes out
 * differently depending on that, which is why the `page_navbar` catalog
 * sample is a "kind: page" sample, served through a real running app
 * rather than rendered with `renderTags()` (see docs/markup-catalog.md's
 * render rules). Confirmed by diffing a real `shiny::runApp()` response
 * against an as.character() dump of the exact same page_navbar() call:
 * outside Shiny, the active tab is `<li class="active"><a data-toggle=
 * "tab">`, no "nav-link" class anywhere; inside a real running app, it is
 * `<li class="nav-item"><a class="nav-link active" data-toggle="tab">` -
 * full BS5-native shape, every tab's <li> gets "nav-item", only the
 * selected tab's <a> gets "active". bs_global_set() first makes no
 * difference (tried it); this is not a theme-resolution issue.
 *
 * This second shape is the one that matters, for two reasons, not just
 * cosmetic polish:
 * - bslib's own `.nav-underline :where(ul.nav.navbar-nav > li)>a.active`
 *   CSS rule (the underline that marks the active tab) needs "active" ON
 *   THE <a>, not the <li>. Rendering "active" on <li> only, the way the
 *   stale fixture shows, means the CSS rule can never match, so the
 *   active tab never gets its underline - confirmed live against a real
 *   running parent app, which does show it.
 * - Shiny's own BootstrapTabInputBinding.getValue() branches on isBS3()
 *   (`!window.bootstrap`, false once real Bootstrap 5 JS is loaded, which
 *   every page_navbar app here does): false means it looks for
 *   `.nav-link:not(.dropdown-toggle).active` to read the current tab, the
 *   same selector the CSS needs. No app here reads input$nav server-side
 *   yet, so this has stayed invisible, but it is a real latent gap, not
 *   just missing polish.
 *
 * Written by hand, not hosted through renderUI() like the input widgets,
 * because this <ul> holds a mix of hosted tab links and real React siblings
 * (nav_spacer, a Level R study chip, hosted buttons) that all need to live
 * in the same list. useBoundScope(ref, (el) => el.parentElement) is what
 * turns this into a real input: it runs Shiny.initializeInputs()/bindAll()
 * over the <ul>'s PARENT, not the <ul> itself. That is not a stylistic
 * choice - every Shiny binding's find(scope), including the tab-input
 * binding that looks for ul.shiny-tab-input, is $(scope).find(selector),
 * which is descendants-only and therefore EXCLUDES scope itself. Passing
 * the <ul> as its own scope (an earlier version of this component did)
 * never actually finds or binds it, no matter how many times bindAll
 * runs: clicking a tab silently never produces an input$<id> update
 * server-side. Passing the parent instead means the <ul> is a descendant
 * of the scanned scope, so find() actually reaches it.
 *
 * The `children` prop is withheld until useBoundScope reports ready (see
 * its own file comment for the full "why": in short, any hosted output
 * among `children` must not exist in the DOM while the manual bindAll()
 * call above is still in flight, or shiny.js's own async bindOutputs() and
 * that output's own bind pass can both discover it "unbound" and both
 * register it, which Shiny logs as a duplicate output id). The tab <li>
 * items themselves are NOT withheld - they carry no hosted output of their
 * own, only plain data-value/href tab links, so there is nothing there for
 * a concurrent bind pass to double-register, and withholding them too
 * would just make every tab strip flash empty on first paint for nothing.
 *
 * The a[href] fragments are invented here (bslib's own are a random
 * tabsetid), so tabPaneId() is exported for TabPane to build matching ids;
 * only the data-value attribute has to match the parent byte for byte,
 * since that is the string Shiny reports as input$<id>.
 */
export function NavbarTabStrip({ id, panels, children }: Props) {
  const fullId = useNs(id);
  const ref = useRef<HTMLUListElement>(null);
  const childrenReady = useBoundScope(ref, (el) => el.parentElement);

  // The first PANEL overall wins the default "active" state - flattened
  // across top-level tabs AND any dropdown's own sub-panels, in declaration
  // order, matching bslib/shiny's own "first tabPanel declared wins" default.
  // Every app in this repo so far defaults to a top-level panel (genescout's
  // own default, "Review", included), so a dropdown's own toggle getting
  // "active" when ITS child is the default has no live-verified example yet;
  // kept here anyway since it is a one-line correct generalization of the
  // same rule, not a guess at a different shape.
  let flatIndex = 0;

  return (
    <ul ref={ref} id={fullId} className="nav navbar-nav nav-underline shiny-tab-input">
      {panels.map((entry) => {
        if (isDropdown(entry)) {
          let toggleActive = false;
          const items = entry.dropdown.map((p) => {
            const active = flatIndex === 0;
            flatIndex++;
            if (active) toggleActive = true;
            return (
              <li key={p.value}>
                <a
                  href={`#${tabPaneId(id, p.value)}`}
                  data-toggle="tab"
                  data-bs-toggle="tab"
                  data-value={p.value}
                  className={cx("dropdown-item", active && "active")}
                >
                  {p.label}
                </a>
              </li>
            );
          });
          return (
            <li key={entry.label} className="dropdown nav-item">
              <a
                href="#"
                className={cx("dropdown-toggle nav-link", toggleActive && "active")}
                data-toggle="dropdown"
                data-bs-toggle="dropdown"
                data-value={entry.label}
              >
                {entry.label}
                <b className="caret" />
              </a>
              <ul className="dropdown-menu">{items}</ul>
            </li>
          );
        }
        const active = flatIndex === 0;
        flatIndex++;
        return (
          <li key={entry.value} className="nav-item">
            <a
              href={`#${tabPaneId(id, entry.value)}`}
              data-toggle="tab"
              data-bs-toggle="tab"
              data-value={entry.value}
              className={cx("nav-link", active && "active")}
            >
              {entry.icon && (
                <i
                  className={`fas ${entry.icon} fa-fw`}
                  role="presentation"
                  aria-label={`${entry.icon.replace(/^fa-/, "")} icon`}
                />
              )}
              {entry.label}
            </a>
          </li>
        );
      })}
      {childrenReady && children}
    </ul>
  );
}

/** bslib::nav_spacer(). */
export function NavSpacer() {
  return <div className="bslib-nav-spacer" />;
}

/** bslib::nav_item(). A plain wrapper li for anything that is not a tab. */
export function NavItem({ children }: { children: ReactNode }) {
  return <li className="bslib-nav-item nav-item form-inline">{children}</li>;
}
