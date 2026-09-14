library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Slider",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "bins",
    sliderInput("bins", "Bins", min = 1, max = 50, value = 30)
  )

  output$plot <- renderPlot({
    req(input$bins)
    hist(rnorm(input$bins), main = NULL, col = "#447099", border = "white")
  })
}

shinyApp(ui, server)
