library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Text area",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "genes",
    textAreaInput(
      "genes",
      label = NULL,
      rows = 3,
      placeholder = "GENE1, GENE2, GENE3..."
    )
  )
  output$echo <- renderText(input$genes)
}

shinyApp(ui, server)
