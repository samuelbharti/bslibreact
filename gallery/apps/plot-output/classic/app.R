# Classic bslib + Shiny: a plot output on its own, fed by a fixed dataset.
library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Plot"),
    plotOutput("plot")
  )
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    plot(pressure, col = "#447099", pch = 19)
  })
}

shinyApp(ui, server)
