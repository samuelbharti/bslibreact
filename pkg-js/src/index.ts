// Barrel export. Every app imports the kit as one package:
//   import { Card, SliderInput, useShinyOutputValue } from "bslib-react";

// Real re-export, not a side-effect import: custom-elements.ts augments the
// "react" module's own JSX.IntrinsicElements so TSX can write <bslib-tooltip>
// and friends, but that augmentation only reaches a CONSUMING app's own TS
// program if this package's own declaration emit carries a reference to the
// file forward. A side-effect import (`import type {} from "./custom-elements"`)
// has no named binding, so tsc's declaration emit drops it entirely once this
// is a published package rather than in-tree source: the augmentation still
// applies inside this package's own build, but a consuming app compiling
// against dist-npm/types never sees custom-elements.d.ts at all, and
// <bslib-tooltip> stops type-checking there. Re-exporting the real,
// named prop interfaces gives declaration emit something to follow instead.
export type { BslibTooltipProps, BslibLayoutColumnsProps } from "./custom-elements";

export * from "./shinyreact";
export * from "./cx";

export * from "./module/Module";

export * from "./inputs/HostedInput";
export * from "./inputs/useHostedInputValue";
export * from "./inputs/SelectInput";
export * from "./inputs/SelectizeInput";
export * from "./inputs/RadioButtons";
export * from "./inputs/CheckboxInput";
export * from "./inputs/SliderInput";
export * from "./inputs/ActionButton";
export * from "./inputs/TextAreaInput";
export * from "./inputs/FileInput";
export * from "./inputs/DarkModeInput";
export * from "./inputs/TextInput";
export * from "./inputs/ActionLink";
export * from "./inputs/DownloadButton";
export * from "./inputs/NumericInput";
export * from "./inputs/PasswordInput";
export * from "./misc/HelpText";

export * from "./outputs/PlotOutput";
export * from "./outputs/TextOutput";
export * from "./outputs/TableOutput";
export * from "./outputs/ReactableOutput";
export * from "./outputs/WidgetOutput";
export * from "./outputs/UiOutput";

export * from "./card/Card";
export * from "./card/ValueBox";
export * from "./layout/LayoutColumns";
export * from "./tooltip/Tooltip";
export * from "./layout/Sidebar";
export * from "./page/PageSidebar";
export * from "./page/PageFillable";
export * from "./page/PageNavbar";
export * from "./page/usePageBody";
export * from "./nav/NavbarTabStrip";
export * from "./nav/TabPane";
