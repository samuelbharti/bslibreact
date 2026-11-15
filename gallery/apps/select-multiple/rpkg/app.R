library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Select (multiple)",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "x",
    selectInput("x", "Pick genes", choices = c("A", "B", "C"), multiple = TRUE)
  )
  output$selected <- renderText(paste(
    "Selected:",
    paste(input$x, collapse = ", ")
  ))
}

shinyApp(ui, server)
