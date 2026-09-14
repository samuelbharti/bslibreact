library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Task button"),
    input_task_button("run", "Run analysis"),
    textOutput("status")
  )
)

server <- function(input, output, session) {
  output$status <- renderText(paste("Ran", input$run, "times"))
}

shinyApp(ui, server)
