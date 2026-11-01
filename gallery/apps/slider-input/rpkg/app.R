library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
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
