library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Plot (click input)",
  theme = app_theme
)

server <- function(input, output, session) {
  output$plot <- renderPlot(plot(mtcars$wt, mtcars$mpg))
  output$info <- renderPrint({
    req(input$plot_click)
    nearPoints(mtcars, input$plot_click, xvar = "wt", yvar = "mpg")
  })
}

shinyApp(ui, server)
