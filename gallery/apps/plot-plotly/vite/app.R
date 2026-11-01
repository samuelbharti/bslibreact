library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)
library(plotly)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Plot (plotly)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$plot <- renderPlotly(plot_ly(
    mtcars,
    x = ~wt,
    y = ~mpg,
    type = "scatter",
    mode = "markers"
  ))
}

shinyApp(ui, server)
