import { useState } from "react";
import type { GalleryExample } from "./data/examples";

type Mode = "classic" | "react";

/**
 * One gallery entry: a mode switch (classic bslib + Shiny vs bslib-react +
 * shinyreact) that swaps the live demo, and a separate "Code" toggle that
 * shows both flavors' source side by side, regardless of which mode is
 * live, so the two are always easy to compare directly.
 *
 * The classic demo is a real, live shinylive app running fully in the
 * browser. The react demo is a screenshot of the same app, really running,
 * not a live iframe: shinyreact and bslib-react have no WebAssembly build
 * yet, so shinylive cannot export them (see scripts/export-shinylive.R).
 * The code shown is the exact source that produced both.
 */
export function ExampleCard({ example }: { example: GalleryExample }) {
  const [mode, setMode] = useState<Mode>("classic");
  const [showCode, setShowCode] = useState(false);

  return (
    <div className="example-card">
      <div className="example-card-header">
        <h3>{example.title}</h3>
        <div className="mode-switch" role="tablist" aria-label={`${example.title} mode`}>
          <button
            type="button"
            role="tab"
            aria-selected={mode === "classic"}
            className={mode === "classic" ? "active" : ""}
            onClick={() => setMode("classic")}
          >
            bslib + Shiny
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={mode === "react"}
            className={mode === "react" ? "active" : ""}
            onClick={() => setMode("react")}
          >
            bslib-react + shinyreact
          </button>
        </div>
      </div>

      <p className="example-note">{example.note}</p>

      <div className="example-demo">
        {mode === "classic" ? (
          <iframe
            title={`${example.title}, classic bslib + Shiny`}
            src={example.classicHref}
            loading="lazy"
          />
        ) : (
          <img
            src={example.reactScreenshot}
            alt={`${example.title}, running with bslib-react and shinyreact`}
          />
        )}
      </div>

      <button
        type="button"
        className="code-toggle"
        aria-expanded={showCode}
        onClick={() => setShowCode((v) => !v)}
      >
        {showCode ? "Hide code" : "Show code"}
      </button>

      {showCode ? (
        <div className="code-panel">
          <div>
            <h4>bslib + Shiny</h4>
            <pre>
              <code>{example.classicCode}</code>
            </pre>
          </div>
          <div>
            <h4>bslib-react + shinyreact</h4>
            <pre>
              <code>{example.reactCode.r}</code>
            </pre>
            <pre>
              <code>{example.reactCode.tsx}</code>
            </pre>
          </div>
        </div>
      ) : null}
    </div>
  );
}
