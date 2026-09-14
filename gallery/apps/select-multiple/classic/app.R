library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Select (multiple)"),
    selectInput("x", "Pick genes", choices = c("A", "B", "C"), multiple = TRUE),
    textOutput("selected")
  )
)

server <- function(input, output, session) {
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$x, collapse = ", ")
  ))
}

shinyApp(ui, server)
