# Changelog

## 0.1.0

- Initial extraction from `shinyreact-apps`' `packages/bslib-react` into its
  own package, published as `bslib-react` on npm.
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
