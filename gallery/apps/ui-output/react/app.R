library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "UI",
  theme = app_theme
)

server <- function(input, output, session) {
  host_input(
    output,
    "show_extra",
    checkboxInput("show_extra", "Show extra control", value = FALSE)
  )
  output$extra <- renderUI({
    req(!is.null(input$show_extra))
    if (input$show_extra) {
      sliderInput("extra_slider", "Extra", 1, 10, 5)
    } else {
      NULL
    }
  })
}

shinyApp(ui, server)
