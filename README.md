README for the R shiny HappyStates.app
======================================

This is an application for the R shiny package. It reads in a file with Twitter
tweet data containing the text of the tweet, the location it was sent from, and a
score for the happiness of the tweet and plots the positions of the tweets and
barplots and colored maps to indicate the happiness of states in the US.

The application consists of the files ui.R and server.R and requires and input
file tweet_coordinates.csv that was produced with the Python program
happyStates.py.

To download and run it open and R and type:

    library(shiny)
    
    # Run it using runGitHub
    runGitHub("shiny_HappyStates", "JensAdamczak")
    
    # Run a tar or zip file directly
    runUrl("https://github.com/JensAdamczak/shiny_HappyStates/archive/master.tar.gz")
    runUrl("https://github.com/JensAdamczak/shiny_HappyStates/archive/master.zip")

The application should open in the default browser of the system. It was tested
on Firefox 24.0.  
