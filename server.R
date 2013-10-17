library(shiny)
library(maps)
data(world.cities)

# Get the tweet ratings from happyStates.py.
tweet.coord <- read.csv("tweet_coordinates.csv", header=TRUE)

# Remove Alaska from the data, the map is only for mainland states.
tweet.coord <- tweet.coord[tweet.coord$state != "Alaska", ]
tweet.coord$state <- factor(tweet.coord$state) # drop factor level

# Calculate the total and averge happiness score for each state.
score <- tapply(tweet.coord$score, tweet.coord$state, sum)
score.avg <- tapply(tweet.coord$score, tweet.coord$state, mean)

# Get number of tweets for each state. 
n.tweets <- tapply(tweet.coord$score, tweet.coord$state, length)

# Create a color palette ranging from black:sad to red:happy.
color.fun <- colorRamp(c("black","red"))

n.tweets.col <- (n.tweets + abs(min(n.tweets))) / 
                (max(n.tweets) + abs(min(n.tweets)))
score.col <- (score + abs(min(score))) / (max(score) + abs(min(score)))
score.avg.col <- (score.avg + abs(min(score.avg))) / 
                 (max(score.avg) +abs(min(score.avg)))

cols.n <- rgb(color.fun(n.tweets.col), maxColorValue=256)
cols <- rgb(color.fun(score.col), maxColorValue=256)
cols.avg <- rgb(color.fun(score.avg.col), maxColorValue=256)

# Make list of states.
states <- names(score)
state.list <- as.list(states)
names(state.list) <- states

# Match state names with map regions to get the right colors.
mapnames <- map("state", plot=FALSE)$names
region.list <- strsplit(mapnames, ":")
mapnames2 <- sapply(region.list, "[", 1)
m <- match(mapnames2, tolower(states))
map.col <- cols[m]
map.col.avg <- cols.avg[m]
map.col.n <- cols.n[m]

# Get large cities to overplot later.
us.cities <- world.cities[world.cities$country.etc == "USA", ]
us.cities <- us.cities[us.cities$pop > 50000, ]

# Divide into positive and negative happiness scores.
positive = tweet.coord$score > 0
negative = tweet.coord$score < 0

min.value <- abs(min(tweet.coord$score))

# Define shiny server setup 
shinyServer(function(input, output) {

  # Define list of states for selection in Tab1.
  output$statelist <- renderUI({
    selectInput("regions", "Select state:",
    c(list("US" = "."), state.list))
  })

  # Plot map with tweet positions for Tab1.
  output$tweetMap <- renderPlot({
    map("state", regions=input$regions, interior=FALSE)
    map("state", boundary = FALSE, col="gray", add = TRUE)

    # Plot major US cities.
    if (input$cities == TRUE) {
      points(us.cities$lon, us.cities$lat, pch=21, bg="magenta")
    }
    # Plot positive tweets.
    smiley <- "\U263A" # plot symbol 
    if (input$positive == TRUE) {
      points(tweet.coord$lon[positive], tweet.coord$lat[positive], 
             pch=smiley, col=rgb(1, 0, 0, 0.8), lwd=0.5, 
             cex=(tweet.coord$score[positive]+min.value)/10)
    }
    # Plot negative tweets.
    if (input$negative == TRUE) {
      points(tweet.coord$lon[negative], tweet.coord$lat[negative], 
             pch=1, col=rgb(0, 0, 0.9, 0.8), lwd=2, 
             cex=(tweet.coord$score[negative]+min.value)/10)
    }
    points(-104.014722, 30.681444, pch=4, col="green", lwd=2)
  })

  data <- reactive({
    data <- switch(input$quant,
                   ntweets = list(values=n.tweets, 
                                  colors=cols.n, 
                                  main="Number of tweets", 
                                  map.cols=map.col.n),
                   happ.total = list(values=score, 
                                     colors=cols, 
                                     main="Total happiness",
                                     map.cols=map.col),
                   happ.avg = list(values=score.avg, 
                                   colors=cols.avg, 
                                   main="Average happiness", 
                                   map.cols=map.col.avg)
                  )
    return(data)
  })

  # Plot barplot for Tab2.
  output$stateBar <- renderPlot({
    barplot(data()$values, las=2, col=data()$colors, 
            ylab=data()$main, main=data()$main)
  })

  # Plot color US map for Tab2.
  output$stateMap <- renderPlot({
    map("state", interior=FALSE)
    map("state", fill=TRUE, col=data()$map.cols, add=TRUE)
  })

  # Print most positive tweets for Tab3.
  output$tweets.pos <- renderTable({
    head(tweet.coord[order(tweet.coord$score, decreasing=TRUE), c(6, 7)], 
         n=input$ntop)
  })
  output$tweets.neg <- renderTable({
    head(tweet.coord[order(tweet.coord$score), c(6, 7)], n=input$nbottom)
  })
})