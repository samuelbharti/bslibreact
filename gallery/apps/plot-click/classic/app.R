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
  output$plot <- renderPlot({
    par(cex.main = 1.4, cex.lab = 1.3, cex.axis = 1.15, mar = c(5, 5, 2, 1))
    plot(
      mtcars$wt,
      mtcars$mpg,
      col = "#447099",
      pch = 19,
      cex = 1.3,
      xlab = "Weight (1000 lbs)",
      ylab = "Miles per gallon"
    )
  })
  output$info <- renderPrint({
    req(input$plot_click)
    nearPoints(mtcars, input$plot_click, xvar = "wt", yvar = "mpg")
  })
}

shinyApp(ui, server)
