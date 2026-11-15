library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslibreact_dep(),
  title = "Date range selector",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "dates", dateRangeInput("dates", "Date range"))
  output$chosen <- renderText({
    req(input$dates)
    paste("From", input$dates[1], "to", input$dates[2])
  })
}

shinyApp(ui, server)
