import { CATEGORIES, EXAMPLES } from "./data/examples";
import { ExampleCard } from "./ExampleCard";

export function App() {
  return (
    <main>
      <header className="gallery-header">
        <h1>bslib-react component gallery</h1>
        <p>
          Every example below runs both ways: the classic{" "}
          <a href="https://rstudio.github.io/bslib/">bslib</a> +{" "}
          <a href="https://shiny.posit.co/">Shiny</a> version, and the{" "}
          <a href="https://github.com/samuelbharti/bslib-react">bslib-react</a> +{" "}
          <a href="https://github.com/posit-dev/shinyreact">shinyreact</a> version. Switch between
          them, or show the code for both side by side.
        </p>
      </header>

      {CATEGORIES.map(({ key, label }) => {
        const items = EXAMPLES.filter((e) => e.category === key);
        if (items.length === 0) return null;
        return (
          <section key={key}>
            <h2>{label}</h2>
            <div className="example-grid">
              {items.map((example) => (
                <ExampleCard key={example.slug} example={example} />
              ))}
            </div>
          </section>
        );
      })}
    </main>
  );
}
