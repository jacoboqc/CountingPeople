
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
library(scales); 
library(grid); 
library(RColorBrewer)

source("./server-functions.R")
refresh <- 5
# begin <- Sys.time() - 1200
begin <- as.POSIXct("2017-03-31 12:20:40 CEST")
end <- begin + refresh
mac_df <- data.frame()
mac_list <- data.frame()
sec2milis <- function(x){x*1000}
delete <- TRUE
shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    refresh <- input$s
    cat(file=stderr(),refresh, "------------------- \n")
    cat(file=stderr(),"Before the API request", "\n")
    
    invalidateLater(sec2milis(refresh), session)
    cat(file=stderr(),"Before the API request", "\n")
    # mac_list <<- getAllMacsByTimestamp(begin=begin, end=end,
    #             endpoint = "http://192.168.2.102:3000/macs/interval")
    mac_list <<- getAllMacsByTimestamp(begin=begin, end=end)
    cat(file=stderr(),"After the API request", "\n")
    # woul not be necessary if filtering was done at the api
    # important: interval open on one side
    mac_list <<- mac_list[mac_list$time >= begin & mac_list$time < end,]
    cat(file=stderr(),"rows in temporal list", nrow(mac_list), "\n")
    cat(file=stderr(),"columns in temporal list", ncol(mac_list), "\n")
    cat(file=stderr(),"rows in permanent list", nrow(mac_df), "\n")
    cat(file=stderr(),"columns in permanent list", ncol(mac_df), "\n")
    names(mac_list) <<- c("MAC", "device", "ID","timestamp", "type") # important dont move
    # solves match.names problems in rbind
    mac_df <<- rbind(mac_df, mac_list)
    cat(file=stderr(), "names of permanent and temporal dataset", 
        names(mac_df), names(mac_list), "\n")
    print(begin)
    print(end)
    begin <<- begin + refresh
    end <<- end + refresh
  })
  
  # plots amount inside the system (not fixed yet)
  output$devices_inside <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_df$inside <- n_distinct(mac_df$MAC)
    ggplot(mac_df, aes(timestamp,inside)) + geom_col()
  })
  
  #' amount of unique macs in the interval
  #' x axis: time
  #' y axis: mac count per timestamp. 
  output$macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_list$inside <- n_distinct(mac_list$MAC)/2
    ggplot(mac_list, aes(timestamp,inside)) + geom_col()
  })
  
  output$macs_per_second_total <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    mac_df$inside <- n_distinct(mac_df$MAC)/10
    ggplot(mac_df, aes(timestamp,inside)) + geom_col()
    
  })
  
  output$time_per_mac <- renderPlot({
  #  ## straw
  #  getMinOrMax <- function(mac, data, min_or_max, mac_col, time_col){
  #    min_or_max(data[data[mac_col]==mac, time_col])
  #   }
  # mapply(f, unlist(lista_macs), MoreArgs=list(data=macs, mac_col="mac", min_or_max=min, time_col="time"))
  # ##
  # x <- runif(n_distinct(mac_df$MAC), min = 0, max = as.numeric(end-begin)/15)
  # plot(x)

  })
  
  output$static_annalyse <- renderPrint({
    try(system("python3.6 ../static_stats.py", intern = FALSE, wait = FALSE))
    #try(system("ls ui.R", intern = TRUE, ignore.stderr = TRUE))
    
  })
  
  output$static_total_mac <- renderImage({
    if(file.exists("img/time_in_system.jpg")){
      assign("delete", TRUE, envir = .GlobalEnv)
      list(src = "img/time_in_system.jpg"
           # width = 400,
           # height = 300,
           # alt = "This is alternate text"
      )
    } else{
      assign("delete", FALSE, envir = .GlobalEnv)
      invalidateLater(sec2milis(1), session)
      list(src = "img/loading.gif",
           contentType = 'image/gif'
           # width = 400,
           # height = 300,
           # alt = "This is alternate text"
      )
    }
    }, deleteFile = delete)
})


fte_theme <- function() {
  
  # Generate the colors for the chart procedurally with RColorBrewer
  palette <- brewer.pal("Greys", n=9)
  color.background = palette[2]
  color.grid.major = palette[3]
  color.axis.text = palette[6]
  color.axis.title = palette[7]
  color.title = palette[9]
  
  # Begin construction of chart
  theme_bw(base_size=9) +
    
    # Set the entire chart region to a light gray color
    theme(panel.background=element_rect(fill=color.background, color=color.background)) +
    theme(plot.background=element_rect(fill=color.background, color=color.background)) +
    theme(panel.border=element_rect(color=color.background)) +
    
    # Format the grid
    theme(panel.grid.major=element_line(color=color.grid.major,size=.25)) +
    theme(panel.grid.minor=element_blank()) +
    theme(axis.ticks=element_blank()) +
    
    # Format the legend, but hide by default
    theme(legend.position="none") +
    theme(legend.background = element_rect(fill=color.background)) +
    theme(legend.text = element_text(size=7,color=color.axis.title)) +
    
    # Set title and axis labels, and format these and tick marks
    theme(plot.title=element_text(color=color.title, size=10, vjust=1.25)) +
    theme(axis.text.x=element_text(size=7,color=color.axis.text)) +
    theme(axis.text.y=element_text(size=7,color=color.axis.text)) +
    theme(axis.title.x=element_text(size=8,color=color.axis.title, vjust=0)) +
    theme(axis.title.y=element_text(size=8,color=color.axis.title, vjust=1.25)) +
    
    # Plot margins
    theme(plot.margin = unit(c(0.35, 0.2, 0.3, 0.35), "cm"))
}
