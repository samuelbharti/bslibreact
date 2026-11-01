library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Text box",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "q",
    textInput(
      "q",
      NULL,
      placeholder = "Search accession, title or abstract",
      width = "100%"
    )
  )
  output$echo <- renderText(input$q)
}

shinyApp(ui, server)
