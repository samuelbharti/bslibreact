library(shiny)
library(bslib)
library(plotly)

ui <- page_fillable(
  card(
    card_header("Plot (plotly)"),
    plotlyOutput("plot")
  )
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
