import type { ReactNode } from "react";
import { LayoutSidebar } from "../layout/Sidebar";
import { usePageBody } from "./usePageBody";

type Props = {
  title: string;
  sidebar: ReactNode;
  sidebarWidth?: number;
  children: ReactNode;
};

/**
 * bslib::page_sidebar(). Markup pinned against the `sidebar_layout` catalog
 * sample (bslib 0.12.0). page_react() renders a bare <body>, so this component
 * sets the body classes and style a real page_sidebar() page would have
 * set, then renders the title bar and the sidebar layout.
 */
export function PageSidebar({ title, sidebar, sidebarWidth = 250, children }: Props) {
  usePageBody(
    "bslib-page-fill bslib-gap-spacing bslib-flow-mobile html-fill-container bslib-page-sidebar",
    { padding: "0px", gap: "0px" },
  );

  return (
    <>
      <div className="navbar navbar-static-top">
        <div className="container-fluid">
          <h1 className="bslib-page-title navbar-brand">{title}</h1>
        </div>
      </div>
      <LayoutSidebar
        sidebar={sidebar}
        sidebarWidth={sidebarWidth}
        // page_sidebar()'s own shape (confirmed against the "sidebar_layout"
        // catalog sample): no border, locked open on mobile since this is
        // primary navigation, unlike LayoutSidebar's own plain
        // layout_sidebar()+sidebar() defaults.
        border={false}
        borderRadius={false}
        collapsibleMobile={false}
        openMobile="always"
      >
        {children}
      </LayoutSidebar>
    </>
  );
}
