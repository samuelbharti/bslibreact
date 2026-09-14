library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Radio buttons"),
    radioButtons(
      "values",
      "Values",
      choices = c("Row z-score" = "row", "Expression" = "none")
    ),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  output$selected <- renderText(paste("Selected:", input$values))
}

shinyApp(ui, server)
