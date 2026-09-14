// The gallery's registry: one entry per apps/<slug> directory. Source code
// and screenshots are read from the real app files at build time (via
// Vite's import.meta.glob), so the code panel can never drift from what
// actually runs -- there is nothing here to hand-copy out of sync.

export type Category = "inputs" | "outputs" | "messages";

export type GalleryExample = {
  slug: string;
  category: Category;
  title: string;
  /** Which bslib-react component this exercises, and how. */
  note: string;
  classicCode: string;
  reactCode: { r: string; tsx: string };
  /** Relative to the built site root, e.g. "apps/slider-input/classic/index.html". */
  classicHref: string;
  /** Screenshot of the real, running react-mode app (see README in this
   *  directory for why react mode is a screenshot, not a live iframe, for
   *  now). */
  reactScreenshot: string;
};

// { slug: "slider-input", ... } -- the path segment right after "apps/".
function slugFromPath(path: string): string {
  const match = /\/apps\/([^/]+)\//.exec(path);
  if (!match) throw new Error(`could not extract a gallery slug from ${path}`);
  return match[1]!;
}

const classicCode = import.meta.glob("../../apps/*/classic/app.R", {
  eager: true,
  query: "?raw",
  import: "default",
}) as Record<string, string>;

const reactAppR = import.meta.glob("../../apps/*/react/app.R", {
  eager: true,
  query: "?raw",
  import: "default",
}) as Record<string, string>;

const reactAppTsx = import.meta.glob("../../apps/*/react/src/App.tsx", {
  eager: true,
  query: "?raw",
  import: "default",
}) as Record<string, string>;

const screenshots = import.meta.glob("../../apps/*/react/screenshot.png", {
  eager: true,
  query: "?url",
  import: "default",
}) as Record<string, string>;

function bySlug(globResult: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [path, value] of Object.entries(globResult)) {
    out[slugFromPath(path)] = value;
  }
  return out;
}

const classicBySlug = bySlug(classicCode);
const reactRBySlug = bySlug(reactAppR);
const reactTsxBySlug = bySlug(reactAppTsx);
const screenshotBySlug = bySlug(screenshots);

// Phase 1's representative slice. Category, title, and note come from the
// component inventory done while planning this gallery; add entries here
// as Phase 2 fills in the rest of shiny.posit.co/r/components/.
const REGISTRY: Omit<
  GalleryExample,
  "classicCode" | "reactCode" | "classicHref" | "reactScreenshot"
>[] = [
  {
    slug: "slider-input",
    category: "inputs",
    title: "Slider",
    note: "Dedicated component: SliderInput (hosts shiny::sliderInput()).",
  },
  {
    slug: "plot-output",
    category: "outputs",
    title: "Plot",
    note: "Dedicated component: PlotOutput (hosts shiny::plotOutput()).",
  },
  {
    slug: "value-box",
    category: "outputs",
    title: "Value box",
    note: "Dedicated component: ValueBox (reproduces bslib::value_box()), no input at all.",
  },
  {
    slug: "switch-input",
    category: "inputs",
    title: "Switch",
    note: "No dedicated component yet: hosted through HostedInput, the same generic mechanism SliderInput itself is built on.",
  },
  {
    slug: "notification",
    category: "messages",
    title: "Notification",
    note: "No bslib-react component involved at all: shiny::showNotification() renders through Shiny's own client JS, independent of the component tree.",
  },
];

export const EXAMPLES: GalleryExample[] = REGISTRY.map((entry) => ({
  ...entry,
  classicCode: classicBySlug[entry.slug] ?? "",
  reactCode: {
    r: reactRBySlug[entry.slug] ?? "",
    tsx: reactTsxBySlug[entry.slug] ?? "",
  },
  classicHref: `apps/${entry.slug}/classic/index.html`,
  reactScreenshot: screenshotBySlug[entry.slug] ?? "",
}));

export const CATEGORIES: { key: Category; label: string }[] = [
  { key: "inputs", label: "Inputs" },
  { key: "outputs", label: "Outputs" },
  { key: "messages", label: "Display messages" },
];
