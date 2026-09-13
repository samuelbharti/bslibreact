import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// jsdom, not node: every test in tests/ renders real components with
// @testing-library/react, and several (the bind tests) install a fake
// window.Shiny and dispatch DOM events, so a real DOM implementation is not
// optional here the way it might be for a pure-logic test suite.
//
// globalSetup runs once, in Node, before any test file - see its own file
// comment for why it, not a per-file beforeAll, is what renders the R/Python
// markup catalogs and decides whether the catalog-dependent tests run at
// all this session. setupFiles runs inside EVERY test file's own worker,
// once per file, and is what installs window.shinyreact (see tests/setup.ts).
export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    include: ["tests/**/*.test.{ts,tsx}"],
    globalSetup: ["./tests/global-setup.ts"],
    setupFiles: ["./tests/setup.ts"],
    testTimeout: 10000,
  },
});
