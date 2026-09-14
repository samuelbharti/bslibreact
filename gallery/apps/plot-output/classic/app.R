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
    par(cex.main = 1.4, cex.lab = 1.3, cex.axis = 1.15, mar = c(5, 5, 2, 1))
    plot(
      pressure,
      col = "#447099",
      pch = 19,
      cex = 1.3,
      xlab = "Temperature",
      ylab = "Pressure"
    )
  })
}

shinyApp(ui, server)
