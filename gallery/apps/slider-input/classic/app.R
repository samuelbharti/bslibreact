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
    hist(rnorm(input$bins), main = NULL, col = "#447099", border = "white")
  })
}

shinyApp(ui, server)
