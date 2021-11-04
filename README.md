# WMATA.jl
Julia package which simplifies the process of interacting with WMATA's public API.

# Getting Started 
You will need an API key from [WMATA's developer portal](https://developer.wmata.com/).

You can get up and running with your subscription key using the `WMATA_auth()` function. This function verifies that you have a valid subscription key and sets a global variable called AuthKey after verifying your key.

```
using WMATA
WMATA_auth("your subscription key")
```

# Available Functions
## rail_predictions()
Based on the *Real Time Rail Predictions* methods described in WMATA's documentation [here](https://developer.wmata.com/docs/services/547636a6f9182302184cda78/operations/547636a6f918230da855363f).

```
using WMATA
rail_predictions(StationCode = "All")
```

This function returns a DataFrame containing:

* **Arrival Station:** full name of the station where the train is arriving. 
* **Location Code:** station code for where the train is arriving.
* **Line:** two-letter abbreviation for the line (e.g.: RD, BL, YL, OR, GR, or SV). May also be blank or No for trains with no passengers.
* **Cars:** the Number of cars on a train, usually 6 or 8, but might also return - or NULL.
* **Destination:** abbreviated version of the final destination for a train. This is similar to what is displayed on the signs at stations.
* **Group:** denotes the track this train is on, but does not necessarily equate to Track 1 or Track 2. With the exception of terminal stations, predictions at the same station with different Group values refer to trains on different tracks.
* **Minutes:** minutes until arrival. Can be a numeric value, ARR (arriving), BRD (boarding), ---, or empty.

## station_list()
Returns a DataFrame of station location and address information based on a given LineCode. Omit the *LineCode* to return all stations. 

*LineCode* - can be empty or one of the following two-letter abbreviations: 
* RD - Red
* YL - Yellow
* GR - Green
* BL - Blue
* OR - Orange
* SV - Silver

```
station_list(LineCode = "YL", false)
```

The resulting DataFrame includes:

* **StationName:** name of the station.
* **StationCode:** three digit station code. Can be used as an input to `rail_predictions()`.
* **Latitude:** Latitude.
* **Longitude:** Longitude.
* **City:** the city in which the station is located. 
* **State:** the state in which the station is located. 
* **Zip:** the Zip code in which the station is located.

An additional argument, `IncludeAdditionalInfo`, can be specified via `true/false`. 

```
station_list(LineCode = "YL", IncludeAdditionalInfo = false)
```

This will return the same DataFrame as above, with the following additions:

* **LineCode2:***	Additional line served by this station, if applicable.
* **LineCode3:*** Additional line served by this station, if applicable.
* **LineCode4:*** Additional line served by this station, if applicable. Currently not in use.
* **StationTogether1:** For stations with multiple platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center), the additional StationCode will be listed here.

## station_timings()

Returns a DataFrame of opening and scheduled first/last train times based on a given StationCode.

Note that for stations with multiple platforms (e.g.: Metro Center, L'Enfant Plaza, etc.), a distinct call is required for each StationCode to retrieve the full set of train times at such stations. 

```
station_timings(StationCode = "C14")
```
The resulting DataFrame includes:

* **StationName:** name of the station.
* **StationCode:** three digit station code. Can be used as an input to `rail_predictions()`.
* **DayOfWeek:** the day of the week.
* **OpeningTime:** the time that the station opens.
* **FirstTrainDestination:** the StationCode of the first train's destination.
* **FirstTrainTime:** first train leaves the station at this time. Format is HH:mm. 
* **LastTrainDestination:** the StationCode of the last train's destination.
* **LastTrainTime:** last train leaves the station at this time. Format is HH::mm. Note that when the time is AM, it signifies the next day. For example, a value of 02:30 under a Saturday element means the last train leaves on Sunday at 2:30 AM.
