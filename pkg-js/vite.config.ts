import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The IIFE build: dist/bslibreact.js, the file `make update-dist` vendors
// into pkg-r's inst/lib/ and pkg-py's www/, and a served page attaches as a
// classic <script defer>, loaded right after shinyreact's own dependency
// (see src/global.ts and src/shinyreact.ts's own comments on why load order
// matters here). React and ReactDOM are externalized to
// window.shinyreact.React / .ReactDOM instead of bundled, the same
// external/globals shape examples/01-hello/vite.config.ts uses for an app's
// own ui.js bundle: the page's one shinyreact.js
// dependency already carries a React instance, and bundling a second copy
// here is exactly the "every hook silently returns nothing" failure mode
// that externalizing exists to prevent.
export default defineConfig({
  define: { "process.env.NODE_ENV": JSON.stringify("production") },
  plugins: [react()],
  build: {
    outDir: "dist",
    lib: {
      entry: "src/global.ts",
      formats: ["iife"],
      name: "bslibreact",
      fileName: () => "bslibreact.js",
    },
    rollupOptions: {
      external: ["react", "react-dom", "react-dom/client"],
      output: {
        assetFileNames: "bslibreact.[ext]",
        globals: {
          react: "window.shinyreact.React",
          "react-dom": "window.shinyreact.ReactDOM",
          "react-dom/client": "window.shinyreact.ReactDOM",
        },
      },
    },
  },
});
