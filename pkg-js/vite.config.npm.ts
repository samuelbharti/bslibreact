import path from "node:path";
import { fileURLToPath } from "node:url";

import { defineConfig } from "vite";

const dir = path.dirname(fileURLToPath(import.meta.url));

// The `bslib-react` npm build: ESM, react/react-dom externalized as peer
// dependencies so a bundler-tier app resolves a single React (and keeps its
// own dev build, with Fast Refresh, in development). The IIFE build
// (vite.config.ts) is built from the same source but maps those same
// externals to window.shinyreact instead of leaving them as bare specifiers
// for a bundler to resolve - see that file's own comment. Modeled on
// shinyreact's own pkg-js/vite.config.npm.ts. Type declarations come from
// tsconfig.npm.json, not from this config; Vite's own declaration output is
// not used.
export default defineConfig({
  build: {
    outDir: "dist-npm",
    emptyOutDir: true,
    sourcemap: true,
    lib: {
      entry: path.resolve(dir, "src/index.ts"),
      formats: ["es"],
      fileName: () => "index.js",
    },
    rollupOptions: {
      external: ["react", "react-dom", "react-dom/client", "react/jsx-runtime"],
    },
  },
});
