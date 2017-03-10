
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)
library(tidyr)
library(httr)

addEnteringStatus <- function(data){
  grouped <- data %>% group_by(MAC) %>%  mutate(
    entering=as.logical(rank(timestamp) %% 2))
  # Check if column "entering" changes each time a MAC appears
  return(ungroup(grouped)$entering)
}

addAmountInside <- function(data){
  # Amount of people in each timestamp: sum of "T" until then
  accumulated <- data %>% mutate(
    inside=cumsum(entering)-cumsum(!entering))
  return(accumulated$inside)
}

HTTPresponse2DataFrame <- function(url){
  r <- GET(url)  
  data <- read.csv(text=textConnection(content(r, "text")), header=T)
}

shinyServer(function(input, output) {

  output$time_evol <- renderPlot({
    data <- read.csv("../data.csv")
    data$entering <- addEnteringStatus(data)
    data$inside <- addAmountInside(data)
    smoothScatter(data$timestamp, data$inside, 
                  xlab = "Timestamp", ylab="Amount of devices", main="Devices inside the system")
  })

})
