// Builds every gallery example's vite/src/ui.tsx into vite/www/ui.js,
// one Vite build per example, all sharing this package's own
// node_modules (no per-example package.json). Mirrors the IIFE config in
// examples/01-hello/vite.config.ts: React and ReactDOM externalized to
// window.shinyreact so the bundle shares the React instance that owns
// shinyreact's hooks.
import { existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import react from "@vitejs/plugin-react";
import { build } from "vite";

const galleryDir = dirname(dirname(fileURLToPath(import.meta.url)));
const appsDir = join(galleryDir, "apps");

const slugs = readdirSync(appsDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name)
  .filter((slug) => existsSync(join(appsDir, slug, "vite", "src", "ui.tsx")));

if (slugs.length === 0) {
  console.error("[gallery] no apps/*/vite/src/ui.tsx found, nothing to build");
  process.exit(1);
}

for (const slug of slugs) {
  const appDir = join(appsDir, slug, "vite");
  console.log(`[gallery] building ${slug}/vite`);
  await build({
    root: galleryDir,
    configFile: false,
    logLevel: "warn",
    define: { "process.env.NODE_ENV": JSON.stringify("production") },
    plugins: [react()],
    build: {
      outDir: join(appDir, "www"),
      emptyOutDir: true,
      cssCodeSplit: false,
      target: "es2020",
      lib: {
        entry: join(appDir, "src", "ui.tsx"),
        formats: ["iife"],
        name: "ShinyReactApp",
        fileName: () => "ui.js",
      },
      rollupOptions: {
        external: ["react", "react-dom", "react-dom/client"],
        output: {
          assetFileNames: "ui.[ext]",
          globals: {
            react: "window.shinyreact.React",
            "react-dom": "window.shinyreact.ReactDOM",
            "react-dom/client": "window.shinyreact.ReactDOM",
          },
        },
      },
    },
  });
}

console.log(
  `[gallery] built ${slugs.length} app${slugs.length === 1 ? "" : "s"}: ${slugs.join(", ")}`,
);
