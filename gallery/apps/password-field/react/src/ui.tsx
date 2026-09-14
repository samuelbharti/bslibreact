import App from "./App";

const { ReactDOM } = window.shinyreact;

const container = document.body.appendChild(document.createElement("div"));
container.className = "html-fill-item html-fill-container";

const root = ReactDOM.createRoot(container);
root.render(<App />);
