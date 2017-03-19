
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)
library(tidyr)
library(httr)
library(ggplot2)

source("./server-functions.R")

refresh <- 10
begin <- as.POSIXct("2017-03-19 02:04:42 CEST")
end <- begin + refresh
# mac_df <<- data.frame(row.names = c("MAC","Device", "ID", "timestamp"))
mac_df <- data.frame(row.names = c("MAC","Device", "ID", "timestamp"))
sec2milis <- function(x){x*1000}

shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    invalidateLater(sec2milis(refresh), session)
    begin <<- begin + refresh
    end <<- end + refresh
    print(begin)
    print(end)
  })
  
  output$mac_plot <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_list <- getAllMacsByTimestamp(begin=begin, end=end)
    mac_df <<- rbind(mac_df, mac_list)
    names(mac_df) <- c("MAC","Device", "ID", "timestamp")
    mac_df$entering <- addEnteringStatus(mac_df)
    mac_df$inside <- addAmountInside(mac_df)
    ggplot(mac_df, aes(timestamp,inside)) + geom_line()
  })

})
