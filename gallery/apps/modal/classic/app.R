library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Modal"),
    actionButton("go", "Show modal")
  )
)

server <- function(input, output, session) {
  observeEvent(input$go, {
    showModal(modalDialog(
      title = "Confirm",
      "Are you sure you want to continue?",
      easyClose = TRUE
    ))
  })
}

shinyApp(ui, server)
