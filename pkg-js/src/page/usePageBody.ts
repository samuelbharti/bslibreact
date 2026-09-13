import { useLayoutEffect } from "react";

const HTML_HEIGHT_STYLE_ID = "bslib-html-height";

/**
 * page_react() renders a bare <body>: no class, no style, because the
 * ui.tsx pattern hands the whole document over to the client. bslib's own
 * page_*() functions put fill classes and inline padding/gap styles on
 * <body> itself, so this hook does the same from the top-level page
 * component, matching what the parent app's page function would have set.
 *
 * bslib::page_fillable() - and page_sidebar()/page_navbar(), which call it
 * internally - also inject one more thing this hook has to replicate:
 * `tags$head(tags$style("html { height: 100%; }"))`. Without it, <html>
 * has no height for the fill chain to measure against, so every
 * html-fill-container down the tree sizes to its own content instead of
 * the viewport: this is the cause of the page-height gaps recorded in
 * pca-explorer, volcano-plot, gene-table, and connectivity-table's
 * PORT.md files, and of the badly collapsed chat panel in byok-chat's.
 * Confirmed by reading bslib::page_fillable's own source
 * (`deparse(bslib::page_fillable)`): it always adds this rule, so this
 * hook always adds it too, once per page, regardless of which page
 * component is in use.
 *
 * Runs once per distinct (classes, style) pair; if the app never switches
 * page shells, that is once for the life of the app.
 */
export function usePageBody(classes: string, style: Record<string, string> = {}) {
  useLayoutEffect(() => {
    let styleTag = document.getElementById(HTML_HEIGHT_STYLE_ID) as HTMLStyleElement | null;
    const addedStyleTag = !styleTag;
    if (!styleTag) {
      styleTag = document.createElement("style");
      styleTag.id = HTML_HEIGHT_STYLE_ID;
      styleTag.textContent = "html { height: 100%; }";
      document.head.appendChild(styleTag);
    }

    const body = document.body;
    const previousClass = body.className;
    const previousStyle = body.getAttribute("style");
    body.className = classes;
    Object.assign(body.style, style);
    return () => {
      body.className = previousClass;
      if (previousStyle === null) {
        body.removeAttribute("style");
      } else {
        body.setAttribute("style", previousStyle);
      }
      if (addedStyleTag) {
        styleTag?.remove();
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [classes, JSON.stringify(style)]);
}
