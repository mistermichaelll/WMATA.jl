# WMATA.jl
Julia package which simplifies the process of interacting with WMATA's public API.

You will need an API key from [WMATA's developer portal](https://developer.wmata.com/).

# Available Functions
## rail_predictions()
Based on the *Real Time Rail Predictions* methods described in WMATA's documentation [here](https://developer.wmata.com/docs/services/547636a6f9182302184cda78/operations/547636a6f918230da855363f).

```
using WMATA
sub_key = "your API key"
rail_predictions(sub_key, "All")
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
Returns a Datarame of station location and address information based on a given LineCode. Omit the *LineCode* to return all stations. 

*LineCode* - can be empty or one of the following two-letter abbreviations: 
* RD - Red
* YL - Yellow
* GR - Green
* BL - Blue
* OR - Orange
* SV - Silver

```
using WMATA
sub_key = "your API key"
station_list(sub_key, "YL", false)
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
station_list(sub_key, "YL", IncludeAdditionalInfo = false)
```

This will return the same DataFrame as above, with the following additions:

**LineCode2:***	Additional line served by this station, if applicable.
**LineCode3:*** Additional line served by this station, if applicable.
**LineCode4:*** Additional line served by this station, if applicable. Currently not in use.
**StationTogether1:** For stations with multiple platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center), the additional StationCode will be listed here.