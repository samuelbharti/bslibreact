library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Slider range",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "range",
    sliderInput("range", "Range", min = 0, max = 100, value = c(25, 75))
  )
  output$chosen <- renderText({
    req(input$range)
    paste("From", input$range[1], "to", input$range[2])
  })
}

shinyApp(ui, server)
