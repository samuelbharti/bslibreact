import { createRoot } from "react-dom/client";

import { App } from "./App";

// page_react() emits no body HTML at all -- this entry point owns the DOM
// from here down, same as any other Vite/React app.
const root = createRoot(document.body.appendChild(document.createElement("div")));
root.render(<App />);
