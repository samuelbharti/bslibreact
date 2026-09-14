library(shiny)
library(bslib)
library(gt)

ui <- page_fillable(
  card(
    card_header("Table (gt)"),
    gt_output("table")
  )
)

server <- function(input, output, session) {
  output$table <- render_gt(gt(head(mtcars, 5), rownames_to_stub = TRUE))
}

shinyApp(ui, server)
