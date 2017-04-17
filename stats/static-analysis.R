library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)
library(httr)

#' Reads csv with macs, timestamp, antenna ID and mac type (random or fixed)
#' @param filepath string. Path to file
#' @param timeformat string. 
#' @returns dataframe with timestamps in POSIXct format
read_capture_file <- function(filepath, timeformat = "%Y/%m/%d-%H:%M:%S"){
  data <- read.csv(filepath)
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data
}

#' Receive csv from server with macs, timestamp, antenna ID and mac type (random or fixed)
#' @param url string. url to server 
#' @param timeformat string. 
#' @returns dataframe with timestamps in POSIXct format
read_capture_server <- function(url, timeformat = "%Y/%m/%d-%H:%M:%S"){
  r<- GET(url, accept("text/csv"))  
  data <- read.csv(text=content(r, "text"), header=T)
  # reads all columns as factors, convert if neccesary
  data$time <- as.POSIXct(strptime(data$time, timeformat))
  data
}
#' Returns appearances of each mac for the whole interval
#' @note equals ipython static function "mac_occurs"
#' @param mac_col string or number. Column name of the mac variable
mac_count_distribution <- function(data, mac_col){
 counted <- data %>% count_(mac_col) 
 names(counted) <- c(mac_col, "mac_count")
 counted
}

#' Counts appearances of each unique mac for each interval
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 3 columns: time_col, mac and count. 
#'          many macs per interval
#' @example: distinct_mac(df, "time", "mac", "2 sec")
distinct_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  counted <- data %>% group_by_(time_col) %>% count_(mac_col)
  names(counted) <- c(time_col, mac_col, "mac_count")
  counted[,time_col] <- as.POSIXct(counted[,time_col])
  counted
}

#' Counts appearances of all probe-requests by interval
#' @note equals ipython static function "origin_activity"
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: time_col and mac_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
count_macs_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  counted <- data %>% group_by_(time_col) %>% count_(mac_col) %>% summarise(mac_count = sum(n))
  # note: every operation turns data into a factor.
  counted[[time_col]] <- as.POSIXct(counted[[time_col]])
  counted
}

#' Counts devices per interval. I.e, system ocupation
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: time_col and device_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
count_devices_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  # FIXME: use standard evaluation
  counted <- data %>% group_by_(time_col) %>% 
    summarise(device_count = n_distinct(mac))
  # note: every operation turns data into a factor.
  counted[[time_col]] <- as.POSIXct(counted[[time_col]])
  counted
}

#' Counts appearances of devices by interval, only if they are new
#' @note equals ipython static function "origin_activity"
#' @param data macs dataframe
#' @param time_col string or number. Column of the timestamp variable
#' @param mac_col string or number. Column of the mac variable
#' @param interval passe to cut. Format: "integer unit". See ?cut
#' @returns dataframe with 2 columns: time_col and dev_count. 
#'          the timestamps are not unique, as many as macs
#' @example: distinct_mac(df, "time", "mac", "2 sec")
count_new_devices_interval <- function(data, time_col, mac_col, interval){
  intervals <- cut(data[[time_col]], interval)
  data[,time_col] <- intervals
  # FIXME: time is the column name in NSE (non standard evaluation), should 
  # be obtained from time_col somehow
  counted <- data %>% group_by_(mac_col) %>% top_n(-1, time) %>% ungroup() %>% 
    distinct_(mac_col,time_col) %>% # top_n does not remove duplicates
    # so far, selected first appearances for each mac
    # then macs are counted for each interval
    group_by_(time_col) %>% count_(mac_col) %>% summarise(dev_count = sum(n))
  counted[[time_col]] <- as.POSIXct(counted[[time_col]])
  counted
}

#' Evolution of new macs seen by the system. Always increases (not devices inside)
#' @param count_col string or number. Column with counted macs
#' @returns data frame with a devs_cumsum column instead of a sampled count
devices_accumulated <- function(data, count_col, time_col){
  # FIXME: time, mac_count is NSE, must be converted somehow
  data %>% transmute(time, devs_cumsum = cumsum(dev_count)) 
}

#' For each mac, returns average time between probe request, also called burst
#' @param mac_col string or number. Column with mac addresses
#' @param time_col string or number. Column with timestamps
#' @details timediff column with difference in seconds with the previous 
#'          probe request. 
#' @returns dataframe with two columns:
#'          -"mac_col": mac addresses
#'          -avg_burst: average time difference for each mac
time_between_bursts <- function(data, mac_col, time_col){
  # FIXME: convert time_col and time to SE
  xx <- data %>% group_by_(mac_col) %>%
    # timediff: time diference with the following probe request.
    # time vector is one position up, then substracted
    mutate(timediff = difftime(time,lead(time), units="secs")) %>%
    # 0's and NA are removed before mean calculation
    filter(!is.na(timediff)) %>% filter(timediff > 0) %>%
    summarise(avg_secs = mean(timediff))
}

binned_mac_pairs <- function(data, time_col, interval, mac_filter){
  binned <- bin_in_intervals(data, time_col, interval)
  # FIXME use SE
  filtered_binned <- binned %>%  select(time, mac, type) %>% 
    group_by_(time_col) %>% count_("type") %>% 
    spread_("type", "n", fill = 0)
}

bin_in_intervals <- function(data, reference_col, interval){
  intervals <- cut(data[[reference_col]], interval)
  data[,reference_col] <- as.POSIXct(intervals)
  return(data)
}

plot_date_count <- function(data, date_col, count_col, time_breaks, 
                            geom = geom_col()){
  # aes_string allows passing columns as strings
  ggplot(data, aes_string(x = date_col, y = count_col)) + geom +
    scale_x_datetime(breaks = date_breaks(time_breaks), date_labels = "%M:%S")
}
  

