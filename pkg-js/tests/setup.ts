import * as React from "react";
import * as ReactDOM from "react-dom/client";
import * as shinyreact from "@posit-dev/shinyreact";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

// Runs once per test FILE (vitest's setupFiles, not globalSetup), inside the
// same jsdom worker every test in that file shares. Every component under
// test reads its hooks off window.shinyreact (see src/shinyreact.ts's own
// sr()), so this installs the REAL @posit-dev/shinyreact package there,
// exactly the way a served page's shinyreact.js dependency would, plus the
// React/ReactDOM instances the real package's own IIFE bundle also attaches
// (see shinyreact's own src/global.ts). Using the real package rather than a
// hand-rolled stub means the bind tests exercise ShinyOutput's actual
// dedup-on-concurrent-mount logic, not a guess at what it does.
window.shinyreact = { ...shinyreact, React, ReactDOM };

// @testing-library/react does not auto-cleanup outside a framework preset
// (Jest's jest-dom setup does this for you; vitest does not by default), so
// without this every test after the first one would render into a document
// still holding the previous test's DOM.
afterEach(cleanup);
