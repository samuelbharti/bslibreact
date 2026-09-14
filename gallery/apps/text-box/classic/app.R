library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Text box"),
    textInput(
      "q",
      NULL,
      placeholder = "Search accession, title or abstract",
      width = "100%"
    ),
    textOutput("echo")
  )
)

server <- function(input, output, session) {
  output$echo <- renderText(input$q)
}

shinyApp(ui, server)
