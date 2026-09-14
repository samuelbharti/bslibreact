library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Verbatim text",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "n", sliderInput("n", "N", 1, 100, 42))
  output$summary <- renderPrint({
    req(input$n)
    summary(rnorm(input$n))
  })
}

shinyApp(ui, server)
