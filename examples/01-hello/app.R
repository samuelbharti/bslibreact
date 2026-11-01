# Hello bslib-react, a shinyreact app built with bslib-react.
#
# The client (src/, built to www/ui.js) owns the page. This file holds
# only reactive computation: page_deps() gives the client the same CSS and
# JavaScript a matching bslib page would attach on its own, and
# host_input() hosts one server-rendered widget for the client to display.
library(shiny)
library(bslib)
library(shinyreact)

app_theme <- bs_theme(version = 5)

ui <- page_react(
  title = "Hello bslib-react",
  theme = app_theme,
  bslibreact::page_deps(app_theme)
)

server <- function(input, output, session) {
  # Level H: a server-rendered widget, hosted for the client to display.
  # The client reads this with <SliderInput id="bins_ui" />, and reads the
  # slider's own value the usual way, from input$bins, once it mounts.
  bslibreact::host_input(
    output,
    "bins",
    shiny::sliderInput("bins", "Bins", min = 1, max = 50, value = 30)
  )

  # Level H: a hosted plot. The client reads this with
  # <PlotOutput id="plot" />.
  #
  # req(input$bins): the slider is hosted, so it does not exist in the
  # initial page HTML the way a plain sliderInput() would. Shiny only
  # learns input$bins after the client round-trips the widget's dynamic UI
  # and binds it, which happens after this reactive's first flush. req()
  # holds the output blank until that value actually arrives, instead of
  # erroring on a NULL breaks= argument on session start.
  output$plot <- renderPlot({
    req(input$bins)
    hist(
      rnorm(500),
      breaks = input$bins,
      col = "#447099",
      border = "white",
      main = NULL,
      xlab = "value"
    )
  })

  # Level R: a plain value, read by the client with useShinyOutputValue()
  # rather than hosted, since it is only ever a number formatted as text.
  # Same req() reasoning as output$plot above.
  output$bins_count <- renderText({
    req(input$bins)
    input$bins
  })
}

shinyApp(ui = ui, server = server)
