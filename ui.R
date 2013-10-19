library(shiny)

# Define UI for HappyStates application .
shinyUI(pageWithSidebar(

  # Application title.
  headerPanel("Happy States of America"),

  # Sidebar. 
  sidebarPanel(
    helpText("Twitter tweet sentiment analysis using tweet data from 
             Twitter's API."), 

    # Sidebar panel for Tab1.
    conditionalPanel(condition="input.conditionedPanels=='US'",
      helpText("The symbol size indicates the degree of 'happiness' of each 
               tweet. 'Major cities' are cities with a population over 
               50,000. "),
      uiOutput("statelist"),
      checkboxInput("positive", "Show positive tweets", FALSE),
      checkboxInput("negative", "Show negative tweets", FALSE),
      checkboxInput("cities", "Show major US cities", FALSE),
      br(),
      sliderInput("transpos", "Transparency positive tweets:",
                  min=0, max=1, value=1., step=0.1),
      sliderInput("transneg", "Tramsparency negative tweets:",
                  min=0, max=1, value=1., step=0.1)
    ),
      
    # Sidebar panel for Tab2.
    conditionalPanel(condition="input.conditionedPanels=='States'",
      helpText("'Total happiness' is the sum of the individual happiness scores 
               for each tweet from that state. 'Average happiness' is the mean
               of the happiness scores."),
      radioButtons("quant", "Select quantity to plot:",
                   list("Number of tweets" = "ntweets",
                        "Average happiness" = "happ.avg",
                        "Total happiness" = "happ.total")),
      br(),
      helpText("Select the state quantity to compare to the tweet results. Note:
               The state data is based on the R state data set (state.x77) and
               certainly outdated."),
      uiOutput("statedata"),
      checkboxInput("fitmodel", "Fit linear model", FALSE)
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
      # Tab2: Barplot with number of tweets/happiness + colored US map + state
      #   vs. tweet characteristics.
      tabPanel("States", plotOutput("stateBar", width="auto", height="350px"),
                         plotOutput("stateMap", width="auto", height="400px"),
                         verbatimTextOutput("summary")),
      # Tab3: Tables with most positive and negative tweets. 
      tabPanel("Tweets", h4("Most positive tweets"), tableOutput("tweets.pos"),
                         h4("Most negative tweets"), tableOutput("tweets.neg")), 
      id = "conditionedPanels"
    )
  )
))
