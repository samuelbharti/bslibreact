library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "File input",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "upload",
    fileInput("upload", "de_results.csv", accept = ".csv")
  )
  output$status <- renderText({
    if (is.null(input$upload)) {
      "No file uploaded yet"
    } else {
      paste("Uploaded:", input$upload$name)
    }
  })
}

shinyApp(ui, server)
