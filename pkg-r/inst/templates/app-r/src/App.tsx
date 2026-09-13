import { useShinyInitialized } from "bslib-react";

// Starting point for a new app. Replace this with APP_TITLE's own page
// shell (PageSidebar, PageNavbar, or similar from bslib-react).
export default function App() {
  const ready = useShinyInitialized();
  if (!ready) return null;
  return <p>Replace src/App.tsx with APP_TITLE's own UI.</p>;
}
