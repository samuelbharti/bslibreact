library(shiny)
library(bslib)
library(leaflet)

ui <- page_fillable(
  card(
    card_header("Map (leaflet)"),
    leafletOutput("map")
  )
)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() |> addTiles() |> setView(lng = -0.09, lat = 51.505, zoom = 12)
  })
}

shinyApp(ui, server)
