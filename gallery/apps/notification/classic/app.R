# Classic bslib + Shiny: an action button that shows a notification.
library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Notification"),
    actionButton("go", "Show notification")
  )
)

server <- function(input, output, session) {
  observeEvent(input$go, {
    showNotification("Saved successfully.", type = "message")
  })
}

shinyApp(ui, server)
