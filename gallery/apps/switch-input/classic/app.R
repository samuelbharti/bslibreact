# Classic bslib + Shiny: input_switch(), reflected back as text.
library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Switch"),
    input_switch("enabled", "Enable feature", value = FALSE),
    textOutput("status")
  )
)

server <- function(input, output, session) {
  output$status <- renderText({
    if (isTRUE(input$enabled)) "Feature is on" else "Feature is off"
  })
}

shinyApp(ui, server)
