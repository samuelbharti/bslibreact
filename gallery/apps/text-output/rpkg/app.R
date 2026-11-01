library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Text",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "n", sliderInput("n", "N", 1, 100, 42))
  output$value <- renderText({
    req(input$n)
    paste("You picked", input$n)
  })
}

shinyApp(ui, server)
