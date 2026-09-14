library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Text area"),
    textAreaInput(
      "genes",
      label = NULL,
      rows = 3,
      placeholder = "GENE1, GENE2, GENE3..."
    ),
    textOutput("echo")
  )
)

server <- function(input, output, session) {
  output$echo <- renderText(input$genes)
}

shinyApp(ui, server)
