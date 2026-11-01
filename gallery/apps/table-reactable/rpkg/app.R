library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(reactable)

app_theme <- bs_theme(version = 5)

ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Table (reactable)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$table <- renderReactable(reactable(mtcars))
}

shinyApp(ui, server)
