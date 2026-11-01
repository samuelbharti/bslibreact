library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  title = "Select",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "x",
    selectInput("x", "Quick pick", choices = c("10", "20", "30"))
  )
  output$selected <- renderText(paste("Selected:", req(input$x)))
}

shinyApp(ui, server)
