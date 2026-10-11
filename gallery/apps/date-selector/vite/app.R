library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "Date selector",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(output, "date1", dateInput("date1", "Date"))
  output$chosen <- renderText(paste("Chosen:", req(input$date1)))
}

shinyApp(ui, server)
