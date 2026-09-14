# Classic bslib + Shiny: a slider driving a histogram.
library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Slider"),
    sliderInput("bins", "Bins", min = 1, max = 50, value = 30),
    plotOutput("plot")
  )
)

server <- function(input, output, session) {
  output$plot <- renderPlot({
    par(cex.main = 1.4, cex.lab = 1.3, cex.axis = 1.15, mar = c(5, 5, 2, 1))
    hist(
      rnorm(input$bins),
      main = NULL,
      xlab = "Value",
      ylab = "Frequency",
      col = "#447099",
      border = "white"
    )
  })
}

shinyApp(ui, server)
