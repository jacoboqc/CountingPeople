
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
library(scales)
library(grid)
library(RColorBrewer)

source("./server-functions.R")
source("../static-analysis.R")

refresh <- 5
# begin <- Sys.time() - 1200
begin <- as.POSIXct("2017-03-31 12:08:40 CEST")
end <- begin + refresh
mac_df <- data.frame()
mac_temp <- data.frame()
sec2milis <- function(x){x*1000}
delete <- T

shinyServer(function(input, output, session) {

  output$time_evol <- renderPrint({
    refresh <<- input$s
    cat(file=stderr(),refresh, "------------------- \n")
    cat(file=stderr(),"Before the API request", "\n")
    
    invalidateLater(sec2milis(refresh), session)
    mac_temp <<- getAllMacsByTimestamp(begin=begin, end=end)
    # woul not be necessary if filtering was done at the api
    # important: interval open on one side
    mac_temp <<- mac_temp[mac_temp$time >= begin & mac_temp$time < end,]
    
    cat(file=stderr(),"rows in temporal list", nrow(mac_temp), "\n")
    cat(file=stderr(),"columns in temporal list", ncol(mac_temp), "\n")
    cat(file=stderr(),"rows in permanent list", nrow(mac_df), "\n")
    cat(file=stderr(),"columns in permanent list", ncol(mac_df), "\n")
    names(mac_temp) <<- c("mac", "device", "ID","time", "type") # important dont move
    # solves match.names problems in rbind
    mac_df <<- rbind(mac_df, mac_temp)
    cat(file=stderr(), "names of permanent and temporal dataset", 
        names(mac_df), names(mac_temp), "\n")
    print(begin)
    print(end)
    begin <<- begin + input$s
    end <<- end + input$s
  })
  
  
  output$macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    interval_mac_count <- count_macs_interval(mac_temp, "time", "mac", "1 sec")
    plot_date_count(interval_mac_count, "time", "mac_count", "1 sec")
  })
  
  output$macs_per_second_total <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    interval_mac_count <- count_macs_interval(mac_df, "time", "mac", "1 sec")
    plot_date_count(interval_mac_count, "time", "mac_count", "1 sec")
    
  })
  
  # amount of unique macs in the interval
  output$new_macs_per_second <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    new_macs_count <- count_new_macs_interval(mac_temp, "time", "mac", "1 sec")
    plot_date_count(new_macs_count, "time", "mac_count", "1 sec")
  })
  
  output$time_between_bursts <- renderPlot({
    invalidateLater(sec2milis(refresh), session)
    t_bursts <- time_between_bursts(mac_df, "mac", "time")
    hist(as.numeric(t_bursts$t_burst), main="Average time between bursts")
  })
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
