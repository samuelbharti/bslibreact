library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Numeric input",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "pc",
    numericInput(
      "pc",
      "Loadings for PC",
      value = 1,
      min = 1,
      max = 10,
      step = 1
    )
  )
  output$value <- renderText(paste("PC:", req(input$pc)))
}

shinyApp(ui, server)
