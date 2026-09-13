import App from "./App";

// Only ReactDOM is needed by name here: JSX below compiles through the
// automatic runtime (no React.createElement calls to write out), but both
// still have to come from window.shinyreact so this bundle shares the
// React instance that owns the hooks.
const { ReactDOM } = window.shinyreact;

// page_react() gives no mount container: the client makes its own. The
// fill classes let it sit transparently between <body> and the page shell
// App renders, so bslib's fill layout chain is unbroken.
const container = document.body.appendChild(document.createElement("div"));
container.className = "html-fill-item html-fill-container";

const root = ReactDOM.createRoot(container);
root.render(<App />);
