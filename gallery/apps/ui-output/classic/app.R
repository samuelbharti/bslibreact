library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("UI"),
    checkboxInput("show_extra", "Show extra control", value = FALSE),
    uiOutput("extra")
  )
)

server <- function(input, output, session) {
  output$extra <- renderUI({
    if (input$show_extra) {
      sliderInput("extra_slider", "Extra", 1, 10, 5)
    } else {
      NULL
    }
  })
}

shinyApp(ui, server)
