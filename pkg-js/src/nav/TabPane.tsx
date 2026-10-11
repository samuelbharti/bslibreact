import { createContext, useContext, type CSSProperties, type ReactNode } from "react";
import { tabPaneId } from "./NavbarTabStrip";

// PageNavbar's own `fillable`, so a TabPane inside it defaults to the same
// value, as every nav_panel() does under page_navbar(fillable = TRUE/FALSE).
export const NavbarFillableContext = createContext(false);

type Props = {
  navId: string;
  value: string;
  active?: boolean;
  /** Whether this panel fills the page. Defaults to the surrounding
   *  PageNavbar's `fillable`; set it per pane for page_navbar(fillable =
   *  c("Browse")), where only the listed panels fill. */
  fillable?: boolean;
  children: ReactNode;
};

const fillableStyle = { "--bslib-navbar-margin": "0" } as CSSProperties;

/**
 * One nav_panel()'s content area. Markup pinned against the `page_navbar`
 * and `page_navbar_not_fillable` catalog samples (bslib 0.12.0): navId must be the exact same
 * id NavbarTabStrip was given, so this pane's id matches that tab's href
 * fragment and Bootstrap's own tab.js (already loaded by the page's
 * Bootstrap bundle) can show and hide it. Stays mounted at all times,
 * hidden by Bootstrap's .active class toggle rather than unmounted, so a
 * hosted output on a hidden tab keeps the same suspend behavior it has on
 * the parent.
 *
 * page_navbar()'s own fillable argument can restrict fill behavior to a
 * subset of panels (a fixed-height "Browse" table view next to normal,
 * page-scrolling views, say): a pane left out of that list renders as a
 * bare tab-pane with no fill classes and no inline style at all, not a
 * smaller version of the fillable shape - confirmed by dumping both
 * shapes from R side by side, since guessing this one from the fillable
 * sample alone would have been wrong.
 */
export function TabPane({ navId, value, active = false, fillable: fillableProp, children }: Props) {
  const navbarFillable = useContext(NavbarFillableContext);
  const fillable = fillableProp ?? navbarFillable;
  const classes = fillable
    ? ["tab-pane html-fill-item html-fill-container bslib-gap-spacing", active && "active"]
        .filter(Boolean)
        .join(" ")
    : ["tab-pane", active && "active"].filter(Boolean).join(" ");
  return (
    <div
      className={classes}
      data-value={value}
      id={tabPaneId(navId, value)}
      style={fillable ? fillableStyle : undefined}
    >
      {children}
    </div>
  );
}
