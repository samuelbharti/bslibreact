import path from "node:path";
import { fileURLToPath } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const dir = path.dirname(fileURLToPath(import.meta.url));

// A plain static SPA build, not the IIFE pattern the ui.tsx clients use:
// this is the gallery shell itself (the page that embeds each example),
// not a shinyreact client. scripts/export-shinylive.R writes each
// example's classic app into dist/apps/<slug>/classic/ separately, after
// this build has already emptied and rewritten dist/ (see package.json's
// build script order); it must never overlap with that path.
export default defineConfig({
  base: "./",
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(dir, "src") } },
  build: {
    outDir: "dist",
    emptyOutDir: true,
  },
});
