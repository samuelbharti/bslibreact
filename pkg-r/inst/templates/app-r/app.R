# APP_TITLE, a shinyreact app built with bslib-react.
#
# The client (src/, built to www/ui.js) owns the page. This file holds
# only reactive computation: page_deps() gives the client the same CSS and
# JavaScript a matching bslib page would attach on its own, and
# host_input() hosts one server-rendered widget for the client to display.
library(shiny)
library(bslib)
library(shinyreact)

for (f in list.files("R", pattern = "[.][Rr]$", full.names = TRUE)) {
  source(f)
}

app_theme <- bs_theme(version = 5)

ui <- page_react(
  title = "APP_TITLE",
  theme = app_theme,
  bslibreact::page_deps(app_theme),
  bslibreact::bslib_react_dep()
)

server <- function(input, output, session) {
  # Level R outputs (plain values the client formats itself) go here.

  # Level H: a server-rendered widget, hosted for the client to display.
  # The client reads this with <ShinyOutput id="bins_ui" /> (or the
  # HostedInput component from the bslib-react npm package), and reads the
  # slider's own value the usual way, from input$bins, once it mounts.
  bslibreact::host_input(
    output,
    "bins",
    shiny::sliderInput("bins", "Bins", min = 1, max = 50, value = 30)
  )
}

shinyApp(ui = ui, server = server)
