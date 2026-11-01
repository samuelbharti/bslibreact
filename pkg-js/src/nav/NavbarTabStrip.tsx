import { useRef, type ReactNode } from "react";
import { cx } from "../cx";
import { useNs } from "../module/Module";
import { useBoundScope } from "../bind/useBoundScope";

export type NavPanelDef = {
  value: string;
  label: string;
  /** nav_panel(icon = icon("...")): a Font Awesome class such as
   *  "fa-chart-column", rendered as `<i class="fas <name> fa-fw">` before
   *  the label, as in the `page_navbar_icon` catalog sample. */
  icon?: string;
};

/**
 * shiny::navbarPage()'s navbarMenu(), or bslib's nav_menu(): a dropdown
 * grouping of sub-panels under one label. Renders one
 * `<li class="dropdown nav-item">` holding a `.dropdown-toggle.nav-link` (a
 * caret, no href target; it never becomes an active tab itself) and its own
 * nested `<ul class="dropdown-menu">` of `.dropdown-item` links, one per
 * sub-panel. Pinned against the `page_navbar_dropdown` catalog sample.
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
 * The <ul class="nav ... shiny-tab-input"> bslib::page_navbar() renders,
 * pinned against the `page_navbar`, `page_navbar_icon` and
 * `page_navbar_dropdown` catalog samples: every tab's <li> gets "nav-item"
 * and only the selected tab's <a> gets "active". Both bslib's active-tab
 * underline (`.nav-underline ... > a.active`) and Shiny's Bootstrap 5 tab
 * binding (`.nav-link:not(.dropdown-toggle).active`) read "active" on the
 * <a>; the Bootstrap 3 shape puts it on the <li> instead.
 *
 * Written by hand, not hosted through renderUI(), because the <ul> mixes
 * tab links with React siblings (nav_spacer(), nav_item() content). It is
 * bound as a Shiny input through useBoundScope over its parent, since
 * Shiny's find() is descendants-only and would never find the <ul> as its
 * own scope. `children` waits for that bind (see useBoundScope); the tab
 * links do not, since they hold nothing hosted.
 *
 * Only data-value has to match the parent exactly: it is what Shiny reports
 * as input$<id>. The href fragments are made up here (bslib's are random),
 * which is why tabPaneId() is exported for TabPane.
 */
export function NavbarTabStrip({ id, panels, children }: Props) {
  const fullId = useNs(id);
  const ref = useRef<HTMLUListElement>(null);
  const childrenReady = useBoundScope(ref, (el) => el.parentElement);

  // The first panel declared is active, counting dropdown sub-panels in
  // order, as in bslib; a dropdown whose child is active marks its toggle.
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
