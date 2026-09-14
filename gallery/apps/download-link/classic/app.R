library(shiny)
library(bslib)

ui <- page_fillable(
  card(
    card_header("Download link"),
    downloadLink("dl", "Download the data")
  )
)

server <- function(input, output, session) {
  output$dl <- downloadHandler(
    filename = "data.csv",
    content = function(file) write.csv(mtcars, file)
  )
}

shinyApp(ui, server)
