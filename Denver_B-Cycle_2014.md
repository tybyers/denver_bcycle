# Denver B-Cycle 2014, A Data Study

Tyler Byers

tybyers@gmail.com

August 23, 2015

## Executive Summary

Fill in here

##About B-cycle

Fill in here

##Data Acquisition and Merging

For this report, we obtained data from several sources and combined the data together, taking the following steps.  Most of the intial data download and munging steps can be replicated by looking at the [exploring_bcycle_data.Rmd](https://github.com/tybyers/denver_bcycle/blob/master/exploring_bcycle_data.Rmd) file; most of these steps were too time-intensive to be carried out in a production level script.

 1. Downloaded B-cycle 2014 Trip Data from the [B-Cycle company information webpage](https://denver.bcycle.com/company). We did some date munging and changed variable names to ones that are more R-friendly. 
 2. Obtained B-cycle kiosk data (kiosk name and address) by hand from the [Denver B-cycle homepage](https://denver.bcycle.com/).
 3. Created a list of the 6800 combinations of checkout kiosk/return kiosk.  For each combination, we used the `mapdist` function from R's `ggmap` package to find the approximate bicycling distance and time between each kiosk. Because of the large number of one-way streets in the Denver downtown area, where the kiosks are highly clustered, we chose to find each checkout-return pair's distance separately, rather than finding a single distance for each pair regardless of direction of travel.  This process took three days, because the Google Distance Matrix API (which the `mapdist` function uses) only allows 2500 calls a day.
 4. Found the latitude and longitude for each station using the `geocode` function in the `ggmap` package. 
 5. Obtained an API key from [forecast.io](https://developer.forecast.io/).  Within R, in our exploratory `Rmd` file, we wrote a function to download the weather data from forecast.io.  Each day's hourly data comes in a separate JSON file; we saved each JSON file to a directory.
 6. Within the production script, we merged different parts of the above data in different ways, depending on the specific task goals.  The final merging was to merge aggregated hourly checkout data with the hourly weather data.
 
###A Note about Holidays
For our study, we factored in City of Denver observed holidays.  Denver city celebrates all the same holidays as the federal holidays, with the following exception: Columbus Day is not a city holiday, and is replaced by Cesar Chavez Day, usually in late March.  We only factored in the major [federal holidays](https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/federal-holidays/#url=2014) that result in government and bank closures (with the exception above), and not the lesser holidays. 

##Descriptive Statistics

### Number of Rides
The B-cycle data, as downloaded, contains 377,229 rows of "trip data." Nominally, this means that 377,229 B-cycle trips were taken in 2014.  Indeed, the [2014 Denver B-cycle annual report](https://denver.bcycle.com/docs/librariesprovider34/default-document-library/annual-reports/2014-denver-bike-sharing-annual-report.pdf?sfvrsn=2) claims this to be the number of rides for the year.

However, over 1% of the rides (4279 rides) have the same checkout station as return station with a trip duration of only 1 minute (see Figure 1 below).  We believe these should be filtered out because we believe the majority of these "rides" are likely people checking out a bike, and then deciding after a very short time that this particular bike doesn't work for them.  We believe that most of the same-kiosk rides under 5 minutes or so likely shouldn't count, but we only culled the ones that were one minute long.

![Figure 1: Trip Duration when Checkout Kiosk and Return Kiosk are the same](https://raw.githubusercontent.com/tybyers/denver_bcycle/master/figures/duration_same_kiosk.png)

We also filtered out 258 rides with an "invalid return" station. This could be any number of things, but since finding nominal distance for these rides is very difficult, we filtered these out as well.

With the above, we arrived at an estimate of **372,684 B-cycle rides in 2014**.

### Distance Traveled

As mentioned in bullet #3 in the Data Acquisition section, we used a Google Maps API in the `ggmap` package to derive the between-station distance for each station pair and then for each ride.  Because a large number of rides were returning to the same kiosk, meaning the minimum distance ridden cannot be estimated by Google Maps, we estimated the distance ridden by calculating the average speed of all the other rides (nominal distance ridden divided by the duration), and then applying this average speed to the same-kiosk trip durations, capping the trips at an arbitrary 5 miles.  While it's likely we are underestimating the total distance ridden by a fair amount (perhaps 25%), since many riders will not take the straight-line distance between two stations (especially tourists/non-commuters), we estimate riders rode **at least 616,960 miles** on B-cycle in 2014, with a more likely number 25% higher at 771,200 miles.

###Most Popular and Least Popular Kiosks

#### Most Popular

The following ten kiosks are the most popular kiosks by number of total bike checkouts in 2014.  The return kiosk popularity is very similar.

                  REI          14th & Stout         22nd & Market     18th & California 
                 9898                  8903                  8896                  8363 
         1350 Larimer          13th & Speer Market Street Station          1550 Glenarm 
                 8273                  8128                  8116                  7940 
        16th & Platte Denver Public Library 
                 7714                  7401
                 
#### Least Popular
The following ten kiosks are the least popular kiosks by number of total bike checkouts in 2014.  

                 29th & Zuni           Florida & S. Pearl Louisiana / Pearl Light Rail 
                         780                          987                         1407 
         Ellsworth & Madison                 Pepsi Center                   Denver Zoo 
                        1523                         1610                         1704 
             33rd & Arapahoe                32nd & Julian            Colfax & Garfield 
                        1851                         1926                         1989 
                 32nd & Clay 
                        1997
                        
#### Map of Station Popularity

We used the `ggmap` package to create the following map showing the popularity of the various checkout kiosks (Figure 2). The size of the circle is proportional to the number of checkouts from that kiosk in 2014.

![Figure 2: Kiosk locations and number of checkouts in 2014](https://raw.githubusercontent.com/tybyers/denver_bcycle/master/figures/checkout_kiosk_map.png)