# Changelog

## 0.1.0

First release. Experimental: component props may still change.

- Initial extraction from `shinyreact-apps`' `packages/bslib-react` into its
  own package.
- Fixed the bind-scope defect in `NavbarTabStrip` and `LayoutSidebar`: both
  used to call Shiny's bind functions directly on a scope that could also
  hold a hosted output mounting in the same commit, which produced
  "Duplicate output IDs" console warnings. Both now go through the new
  `useBoundScope` hook, which withholds hosted content until a single,
  isolated bind pass has settled.
- Replaced the old fixture-based markup tests with a live catalog: tests
  render bslib's and py-shiny's own markup from the installed packages at
  test time, instead of comparing against committed HTML files. See
  `docs/markup-catalog.md` at the repo root.
- Dropped `NativeInput`, `escape.ts`, and `inputs/types.ts` (`toChoices`):
  unused across every app that depended on this kit.
- `useBoundScope` unbinds the element it bound rather than whatever the
  ref points at during cleanup, so a node React swaps out does not leave
  its Shiny bindings behind.
- `TabPane` namespaces its id inside a `<Module>` the same way
  `NavbarTabStrip` namespaces its tab links, so tabs switch there too.
