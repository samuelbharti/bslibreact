library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Progress bar"),
    actionButton("go", "Start task")
  )
)

server <- function(input, output, session) {
  observeEvent(input$go, {
    withProgress(message = "Working", value = 0, {
      for (i in 1:10) {
        incProgress(1 / 10)
        Sys.sleep(0.1)
      }
    })
  })
}

shinyApp(ui, server)
