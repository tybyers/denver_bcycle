##--------------------------------------------
##
## Denver B-Cycle 2014 Ridership
##
## Class: PCE Data Science Methods Class
##
## Final Project
##
## See: https://github.com/tybyers/denver_bcycle for project details.
## 
##--------------------------------------------
##
## Tyler Byers
## tybyers@gmail.com
## August 23, 2015
##


##----Import Libraries-----
require(logging)
require(dplyr)
require(ggplot2)
require(readr)
require(lubridate)
require(jsonlite)
require(ggmap)
Sys.setenv(TZ = 'America/Denver')
## Note: Since much data tidying occurred in the "exploring_bcycle_data.Rmd" 
#  file, we don't need to load all the same packages here.

read_bcycle_data <- function(data_path, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Unzipping and reading B-Cycle Data'),logger)
    }
    data <- read.csv(gzfile(data_path))  # DO want strings as factors
    
    if (is.function(logger)){
        loginfo(paste('Done reading B-Cycle Data from file.'),logger)
    }
    
    if (is.function(logger)){
        loginfo(paste('Formatting Date and Time columns'),logger)
    }
    
    data$return_date <- as.Date(data$return_date)
    data$checkout_date <- as.Date(data$checkout_date)
    data$return_datetime <- ymd_hms(data$return_datetime, 
                                    tz = 'America/Denver')
    data$checkout_datetime <- ymd_hms(data$checkout_datetime,
                                      tz = 'America/Denver')
    
    if (is.function(logger)){
        loginfo(paste('Done formatting Date and Time columns'),logger)
    }
    
    data
}

filter_bad_data <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Unzipping and reading B-Cycle Data'),logger)
    }
    
    print('Status of returns locations:')
    print(table(data$ggmap_status))
    num_invalid <- table(data$ggmap_status)['return_invalid']
        
    # Filtering out all returns with a "return_invalid" location
    if (is.function(logger)){
        loginfo(paste('Filtering out', num_invalid, 
                      'lines with invalid return locations.'),logger)
    }
    data <- data %>% filter(ggmap_status != 'return_invalid')
    
    
    if (is.function(logger)){
        loginfo(paste('Inspecting duration of trips with same return',
                      'location as checkout location.'),logger)
    }
    p1 <- data %>% filter(ggmap_status == 'same_kiosk' & duration_mins <= 15) %>%
        ggplot(aes(x = duration_mins)) + 
        geom_histogram(binwidth = 1, fill = 'steelblue', color = 'black') +
        ggtitle('Trip Duration When Return and Checkout Kiosk the Same') +
        xlab('Duration Minutes') + ylab('Number of Trips') 
    plot_filename <- './figures/duration_same_kiosk.png'
    png(filename = plot_filename)
    print(p1)
    
    if (is.function(logger)){
        loginfo(paste('Saved histogram to file:', plot_filename),logger)
    }
    
    dev.off()
    # Result -- filtering out all trips of duration = 1 min when returned
    #  to same kiosk
    nrow_samekiosk_dur1 <- nrow( data %>% filter(ggmap_status == 'same_kiosk' & 
                                                     duration_mins == 1))
    if (is.function(logger)){
        loginfo(paste('Filtering out', nrow_samekiosk_dur1, 
                      'trips with the same return kiosk as checkout kiosk',
                      'where the trip duration is 1 minute.'),logger)
    }
    data <- data %>% filter(ggmap_status != 'same_kiosk' | 
                            (ggmap_status == 'same_kiosk' & 
                                 duration_mins > 1))
    
    data
}

explore_bcycle_data <- function(data, logger = NA) {
    if (is.function(logger)){
        loginfo(paste('Summary Statistics of filtered B-cycle data.'),logger)
    }
    
    print(summary(data))
    print('Note: we do not have distances filled in for same_kiosk 
          returns yet.')
    print('Checkouts per program type:')
    print(sort(table(data$program), decreasing = TRUE))
    print('Users with the most checkouts')
    print(head(sort(table(data$user_id), decreasing = TRUE), 10))
    print('Checkouts per membership type:')
    print(head(sort(table(data$membership_type), decreasing = TRUE), 5))
    print('Top 10 most-used bikes:')
    print(head(sort(table(data$bike), decreasing = TRUE), 10))
    print('Top 10 most-used checkout kiosks:')
    print(head(sort(table(data$checkout_kiosk), decreasing = TRUE), 10))
    print('Least-used checkout kiosks:')
    print(head(sort(table(data$checkout_kiosk)), 10))
    print('Top 10 most-used return kiosks:')
    print(head(sort(table(data$return_kiosk), decreasing = TRUE), 10))
    print('Least-used return kiosks:')
    print(head(sort(table(data$return_kiosk)), 12))
}

map_kiosks <- function(data, logger = NA) {

    stations <- read_station_data(logger)

    if (is.function(logger)){
        loginfo(paste('Getting Denver Map'),logger)
    }
    
    denver <- get_map(location = 'Denver', zoom = 13)
    
    if (is.function(logger)){
        loginfo(paste('Mapping Checkout Kiosk Popularity'),logger)
    }
    
    kiosks_checkout <- data %>% group_by(checkout_kiosk) %>%
        summarise(n_checkouts = n())
    kiosks_checkout$checkout_kiosk <-
        as.character(kiosks_checkout$checkout_kiosk)
    names(stations)[1] <- 'checkout_kiosk'
    stations$checkout_kiosk <- as.character(stations$checkout_kiosk)
    kiosks_checkout <- left_join(kiosks_checkout, stations, 
                                 by = 'checkout_kiosk')
    p1 <- ggmap(denver) +
        geom_point(data = kiosks_checkout,
                   aes(x = lon, y = lat, size = n_checkouts)) + 
        xlab(NULL) + ylab(NULL) + 
        ggtitle('B-Cycle Kiosks by # of Checkouts, 2014')
    p1_filename <- './figures/checkout_kiosk_map.png'
    png(filename = p1_filename, width = 960, height = 960)
    print(p1)
    dev.off()
    if (is.function(logger)){
        loginfo(paste('Saved map to file:', p1_filename),logger)
    }
    
    
    if (is.function(logger)){
        loginfo(paste('Mapping Return Kiosk Popularity'),logger)
    }
    kiosks_return <- data %>% group_by(return_kiosk) %>%
        summarise(n_returns = n())
    kiosks_return$return_kiosk <- 
        as.character(kiosks_return$return_kiosk)
    names(stations)[1] <- 'return_kiosk'
    kiosks_return <- left_join(kiosks_return, stations, 
                                 by = 'return_kiosk')
    p2 <- ggmap(denver) +
        geom_point(data = kiosks_return,
                   aes(x = lon, y = lat, size = n_returns)) + 
        xlab(NULL) + ylab(NULL) + 
        ggtitle('B-Cycle Kiosks by # of Returns, 2014')
    p2_filename <- './figures/return_kiosk_map.png'
    png(filename = p2_filename, width = 960, height = 960)
    print(p2)
    dev.off()
}

read_station_data <- function(logger = NA) {
    
    if (is.function(logger)){
        loginfo(paste('Getting Station Geo Data.'),logger)
    }
    
    station_path <- paste0(getwd(), '/data/stations_address_geocode.csv')
    
    stations <- read_csv(station_path)
    
    stations
}
    
##----Run Main Function ----
if(interactive()){
    
    ##----Setup Test Logger-----
    basicConfig()
    addHandler(writeToFile, file="./testing.log", level='DEBUG')
    logger <- writeToFile
    
    ##----Set Working Directory----
    setwd('~/UW_DataScience/MethodsDataAnalysis/final_project/')
    
    ##----Read B-cycle Data
    # Note the data are gzipped -- is 79 MB inflated
    if(!('bcycle' %in% ls())) {
        bcycle_path <- paste0(getwd(), '/data/bcycle_2014_ggmap_distances.csv.gz')
        bcycle <- read_bcycle_data(bcycle_path, logger)
    } else {
            loginfo(paste('Dataframe \'bcycle\' already exists.',
                          'Not reading from file.  If this is in error,',
                          'please `rm(bcycle)` from workspace and',
                          'try again.'))
    }
    
    bcycle_filtered <- filter_bad_data(bcycle, logger)
    explore_bcycle_data(bcycle_filtered, logger)
    map_kiosks(bcycle_filtered, logger)
    
}