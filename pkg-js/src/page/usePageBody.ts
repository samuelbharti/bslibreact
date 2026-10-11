import { useLayoutEffect } from "react";

const HTML_HEIGHT_STYLE_ID = "bslib-html-height";

/**
 * page_react() renders a bare <body>, but bslib's page_*() functions put
 * fill classes and an inline padding/gap style on <body> itself, so the
 * page components set them here. bslib::page_fillable() (and page_sidebar()
 * and page_navbar(), which build on it) also adds
 * `html { height: 100% }` to <head>; without it the fill chain has no
 * height to measure against and every html-fill-container sizes to its
 * content. This hook adds that rule once per page.
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
