library(dplyr)
library(tidyr)
library(httr)

read_capture <- function(filepath, timeformat = "%Y/%m/%d-%H:%M:%S"){
  data <- read.csv(filepath)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data
}

distinct_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  data %>% group_by_(time_col) %>% count_(mac_col)
  }

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
  # more conversions...
  return(data)
}
