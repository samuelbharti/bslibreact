import * as shinyreact from "@posit-dev/shinyreact";
import { describe, expect, it } from "vitest";
import type { ShinyReactGlobal } from "../src/shinyreact";

/**
 * The hand-written ShinyReactGlobal interface (src/shinyreact.ts) is this
 * package's own model of @posit-dev/shinyreact's public surface - every
 * hook and component in this kit is typed against it, not against the real
 * package's own types, specifically so src/ can stay import-free of
 * "@posit-dev/shinyreact" (see shinyreact.ts's own comment on
 * provideShinyReact() for why the IIFE build needs that independence).
 *
 * That independence is only safe as long as the model stays accurate: if a
 * future @posit-dev/shinyreact release renames or drops something this
 * interface assumes exists, nothing in src/ would fail to compile (the
 * interface would still be internally consistent on its own) - the break
 * would only surface at runtime, the first time a component called
 * `sr().useWhatever()` against a real page and got "is not a function".
 * tests/setup.ts's own assignment of the real module into
 * `window.shinyreact` (typed as ShinyReactGlobal) already catches a SHAPE
 * mismatch at compile time - it is what caught the two real drifts fixed
 * in shinyreact.ts's own history (OutputError's call/type fields, and
 * ImageOutput's width/height/return type) - but it cannot catch a key
 * disappearing from the real package altogether if TypeScript can still
 * structurally satisfy the assignment some other way. This test is that
 * other half: it asserts, at runtime, against the REAL installed package,
 * that every key ShinyReactGlobal declares still exists on it.
 *
 * KEYS is typed as a Record over every ShinyReactGlobal key except
 * React/ReactDOM (those come from "react"/"react-dom/client" themselves,
 * not from @posit-dev/shinyreact) - a Record, not a plain string array, so
 * that BOTH directions of drift between this file and the interface fail
 * to compile: add a key to ShinyReactGlobal without adding it here, and
 * TypeScript reports it missing from KEYS; remove one from
 * ShinyReactGlobal without removing it here, and TypeScript reports KEYS
 * has an unknown property. Either way, this file cannot quietly fall out
 * of sync with the interface it exists to check.
 */
type CheckedKeys = Omit<ShinyReactGlobal, "React" | "ReactDOM">;

const KEYS: Record<keyof CheckedKeys, true> = {
  useShinyInput: true,
  useSetShinyInput: true,
  useShinyInputValue: true,
  useShinyOutputValue: true,
  useShinyOutputStatus: true,
  useShinyOutputError: true,
  useShinyInitialized: true,
  useShinyBusy: true,
  useShinyMessageHandler: true,
  ShinyOutput: true,
  ImageOutput: true,
  ShinyModuleProvider: true,
};

describe("ShinyReactGlobal matches the real @posit-dev/shinyreact package", () => {
  for (const key of Object.keys(KEYS) as Array<keyof CheckedKeys>) {
    it(`still exports ${key}`, () => {
      expect(shinyreact).toHaveProperty(key);
      expect(typeof shinyreact[key as keyof typeof shinyreact]).toBe("function");
    });
  }
});
