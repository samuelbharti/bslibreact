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
- `NavbarTabStrip` builds its tab links from the raw `id`, the same way
  `TabPane` builds its own id, so tabs switch inside a `<Module>` too.
- `TableOutput` is now `DTOutput`, so it is not mistaken for
  `shiny::tableOutput()`, which `UiOutput` hosts.
- The fourteen input names (`SliderInput`, `SelectInput`, ...) are
  exported from one file; each is still `HostedInput`.
- Outputs pass their plain `id` to `ShinyOutput`, which applies the
  `<Module>` namespace itself, so shinyreact's own `ShinyModuleProvider`
  namespaces them too.
- `TabPane` takes its `fillable` default from the surrounding
  `PageNavbar`.
