library(shiny)
library(maps)
data(world.cities)
data(state)

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

# Prepare for model fits
tweet.data <- data.frame(n.tweets=n.tweets, score=score, score.avg=score.avg)
m <- match(rownames(tweet.data), rownames(state.x77))
model.data <- cbind(state.x77[m, ], tweet.data)

# Characteristics for states
state.char <- as.list(colnames(model.data[, 1:8]))
names(state.char) <- state.char

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

min.val <- abs(min(tweet.coord$score))
max.val <- max(tweet.coord$score)

cex.val <- (4* (tweet.coord$score + min.val)) / (min.val+max.val)
cex.val <- (cex.val +0.5)

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
             pch=smiley, col=rgb(1, 0, 0, input$transpos), lwd=0.5, 
             cex=cex.val[positive])
    }
    # Plot negative tweets.
    if (input$negative == TRUE) {
      points(tweet.coord$lon[negative], tweet.coord$lat[negative], 
             pch=1, col=rgb(0, 0, 0.9, input$transneg), lwd=2, 
             cex=cex.val[negative])
    }
  })

  data <- reactive({
    data <- switch(input$quant,
                   ntweets = list(values=n.tweets, 
                                  modelx = model.data$n.tweets,
                                  colors=cols.n, 
                                  main="Number of tweets", 
                                  map.cols=map.col.n),
                   happ.total = list(values=score, 
                                     modelx = model.data$score,
                                     colors=cols, 
                                     main="Total happiness",
                                     map.cols=map.col),
                   happ.avg = list(values=score.avg, 
                                   modelx = model.data$score.avg,
                                   colors=cols.avg, 
                                   main="Average happiness", 
                                   map.cols=map.col.avg)
                  )
    return(data)
  })

  # Define list of state data to plot againts tweet data.
  output$statedata <- renderUI({
    selectInput("statedata", "Select state data:",
    state.char[order(names(state.char))])
  })

  # Plot barplot for Tab2.
  output$stateBar <- renderPlot({
    par(mar=c(7.5, 4.1, 4.1, 2.1)) # more space for x labels
    barplot(data()$values, las=2, col=data()$colors, 
            ylab=data()$main, main=data()$main)
  })
  # Plot color US map for Tab2.
  output$stateMap <- renderPlot({
    par(mfrow=c(1, 2))
    map("state", interior=FALSE)
    map("state", fill=TRUE, col=data()$map.cols, add=TRUE)

    par(mar=c(5.1, 4.5, 4.1, 2.1)) # more space for y labels
    modely <- input$statedata
    # Plot state vs. tweet characteristic
    plot(data()$modelx, model.data[, modely], col=data()$colors, lwd=2,
         xlab=data()$main, ylab=modely)
    if (input$fitmodel == TRUE) {
      lm.state <- lm(model.data[, modely] ~ data()$modelx)
      abline(lm.state, col="red", lwd=2)
    }
  })
  # Print summary for Tab2.
  output$summary <- renderPrint({
    if (input$fitmodel == TRUE) {
      modely <- input$statedata
      y <- model.data[, modely]
      x <- data()$modelx
      summary(lm(y ~ x))
    }
  })
  # Print most positive and most negative tweets for Tab3.
  output$tweets.pos <- renderTable({
    head(tweet.coord[order(tweet.coord$score, decreasing=TRUE), c(6, 7)], 
         n=input$ntop)
  })
  output$tweets.neg <- renderTable({
    head(tweet.coord[order(tweet.coord$score), c(6, 7)], n=input$nbottom)
  })
})
