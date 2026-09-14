library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(reactable)

app_theme <- bs_theme(version = 5)

# reactable's widget JS is built on reactR, which ships React itself as an
# htmltools dependency named "react" (reactR::html_dependency_react()).
# shinyreact::page_react() attaches its own dependency also named "react"
# for this app's own client bundle (the name comes from this app's own
# directory, and every gallery app's shinyreact client lives in a
# directory literally called "react/"). htmltools keeps only the higher
# "version" between two same-named dependencies, and reactR's real version
# ("18.2.0") loses to page_react()'s cache-busting build number, so
# react.min.js/react-dom.js never reach the page and reactable.js throws
# "Cannot read properties of undefined (reading 'useLayoutEffect')" the
# instant it runs. Reattach the same files under a name that cannot
# collide, and list it first so it is on the page before Shiny delivers
# reactable's own widget script (sent down dynamically the first time
# output$table renders, since reactable() is never in the static ui).
react_runtime_dep <- reactR::html_dependency_react()
react_runtime_dep$name <- "reactR-react"

ui <- page_react(
  react_runtime_dep,
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Table (reactable)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$table <- renderReactable(reactable(mtcars))
}

shinyApp(ui, server)
