library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Checkbox"),
    checkboxInput("cluster", "Cluster genes", value = TRUE),
    textOutput("status")
  )
)

server <- function(input, output, session) {
  output$status <- renderText(
    if (input$cluster) "Clustering on" else "Clustering off"
  )
}

shinyApp(ui, server)
