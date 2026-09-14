library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("File input"),
    fileInput("upload", "de_results.csv", accept = ".csv"),
    textOutput("status")
  )
)

server <- function(input, output, session) {
  output$status <- renderText({
    if (is.null(input$upload)) {
      "No file uploaded yet"
    } else {
      paste("Uploaded:", input$upload$name)
    }
  })
}

shinyApp(ui, server)
