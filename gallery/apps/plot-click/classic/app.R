library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Plot (click input)"),
    plotOutput("plot", click = "plot_click"),
    verbatimTextOutput("info")
  )
)

server <- function(input, output, session) {
  output$plot <- renderPlot(plot(mtcars$wt, mtcars$mpg))
  output$info <- renderPrint({
    req(input$plot_click)
    nearPoints(mtcars, input$plot_click, xvar = "wt", yvar = "mpg")
  })
}

shinyApp(ui, server)
