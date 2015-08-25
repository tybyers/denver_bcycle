## Data Directory

This directory holds a number of data files used in the B-cycle data project.  Many of the files are intermediate files and are not needed.  This document outlines where each file is used, and explains the variables, if needed.

### Data for Production-Level Code

These data are used in the production script [bcycle_final_script.R](https://github.com/tybyers/denver_bcycle/blob/master/bcycle_final_script.R):

  * bcycle_2014_ggmap_distances.csv.gz -- Compressed file of B-cycle data.  Data description:
    * "program": B-cycle program
    * "user_id": B-cycle user id
    * "zip": user's zip code
    * "membership_type": membership type that the bike was checked out under
    * "bike": bike ID number
    * "checkout_date","checkout_time","return_date","return_time": Time/Date stamp of transaction
    * "checkout_kiosk","return_kiosk": Name of kiosk 
    * "duration_mins": How long the bike was checked out, in minutes
    * "checkout_datetime","return_datetime": Concatenated date/time values.
    * "ggmap_dist": Google Maps' estimated bicycling distance between checkout/return kiosk
    * "ggmap_seconds": Google Maps' estimated bicycling time between kiosks
    * "ggmap_status": 'ok' if valid checkout/return address; 'return_invalid' if it did not go back to one of the named kiosks; 'same_kiosk' if returned to same kiosk as where it was checked out.
  * ./weather/ -- Contains daily weather JSON files.  See the [forecast.io Forecast API](https://developer.forecast.io/docs/v2) for more information.
  * stations_address_geocode.csv -- Contains kiosk names, addresses, and geocodes (lat/long).

### Original Data

These data were used early in the process for building data sets for the production level code.  We used these in the [exploring_bcycle_data.Rmd](https://github.com/tybyers/denver_bcycle/blob/master/exploring_bcycle_data.Rmd) code. 

  * 2014denverbcycletripdata_public.xlsx -- Rider data, downloaded from the Denver B-cycle page.  See the [B-cycle company page] (https://denver.bcycle.com/company) for more details.
  * bcycle_locations.kml -- Originally downloaded kiosk data; however, this turned out to be from an earlier year and was out-of-date for our purposes.
  * bcycle_stations.xlsx -- Data collected (by hand) on the kiosk locations from the Denver B-cycle page.

### Intermediate Data sets

All data sets with suffix "rds" are intermediate data sets that I saved off in various points in the process.  These are not needed unless you want to make certain sections of the exploring_bcycle_data.Rmd code run faster, should you choose to run it.
