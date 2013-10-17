library(shiny)

# Define UI for HappyStates application .
shinyUI(pageWithSidebar(

  # Application title.
  headerPanel("Happy States of America"),

  # Sidebar. 
  sidebarPanel(
    # Sidebar panel for Tab1.
    conditionalPanel(condition="input.conditionedPanels=='US'",
      uiOutput("statelist"),

      checkboxInput("positive", "Show positive tweets", FALSE),
      checkboxInput("negative", "Show negative tweets", FALSE),
      checkboxInput("cities", "Show major US cities", FALSE)
    ),

    # Sidebar panel for Tab2.
    conditionalPanel(condition="input.conditionedPanels=='States'",
      radioButtons("quant", "Select quantity to plot:",
                   list("Number of tweets" = "ntweets",
                        "Average happiness" = "happ.avg",
                        "Total happiness" = "happ.total"))
    ),

    # Sidebar panel for Tab3.
    conditionalPanel(condition="input.conditionedPanels=='Tweets'",
      numericInput("ntop", "Number of most positive tweets:", 6),
      numericInput("nbottom", "Number of most negative tweets:", 6)
    )
  ),

  # Main window.
  mainPanel(
    tabsetPanel(
      # Tab1: US map with location of tweets.
      tabPanel("US", plotOutput("tweetMap", width="auto", height="600px")),
      # Tab2: Barplot with number of tweets/happiness + colored US map.
      tabPanel("States", plotOutput("stateBar", width="auto", height="350px"),
                     plotOutput("stateMap", width="auto", height="400px")),
      # Tab3: Tables with most positive and negative tweets. 
      tabPanel("Tweets", h4("Most positive tweets"), tableOutput("tweets.pos"),
                         h4("Most negative tweets"), tableOutput("tweets.neg")), 
      id = "conditionedPanels"
    )
  )
))
