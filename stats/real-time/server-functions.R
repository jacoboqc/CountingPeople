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

getAllMacs <- function(url, timeformat = "%Y/%m/%d-%H:%M:%S"){
  r <- GET(url, accept("text/csv"))  
  data <- read.csv(text=content(r, "text"), header=T)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  return(data)
}

getAllMacsByTimestamp <- function(endpoint = "http://localhost:3000/macs/interval" ,
                                  begin, end, timeformat = "%Y/%m/%d-%H:%M:%S"){
  # if none specified, function default is used
  begin <- format(begin, timeformat)
  end <- format(end, timeformat)
  url <- paste(endpoint,"?start=",begin,"&end=",end, sep="")
  r<- GET(url, accept("text/csv"))  
  data <- read.csv(text=content(r, "text"), header=T)
  # reads all columns as factors, convert if neccesary
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data$mac <- as.character(data$mac)
  return(data)
}
# para usar con mapply o sapply
getMinOrMax <- function(mac, data, min_or_max, mac_col, time_col){
  min_or_max(data[data[mac_col]==mac, time_col])
}
