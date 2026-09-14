# Classic bslib + Shiny: a value box, no input at all.
library(shiny)
library(bslib)

ui <- page_fillable(
  value_box(
    title = "Genes used",
    value = textOutput("ngenes"),
    theme = "primary"
  )
)

server <- function(input, output, session) {
  output$ngenes <- renderText("248")
}

shinyApp(ui, server)
