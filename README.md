# WMATA.jl
Julia package which simplifies the process of interacting with WMATA's public API via an opinionated wrapper to Julia's `DataFrames` package.

# Getting Started 
## Installation 
Install the package from GitHub via Julia's package system: 

```julia 
pkg> add "https://github.com/mistermichaelll/WMATA.jl"
```

## Using the Package
You will need an API key from [WMATA's developer portal](https://developer.wmata.com/).

You can get up and running with your subscription key using the `WMATA_auth()` function. This function verifies that you have a valid subscription key and sets a global struct called `wmata` that is accessible by the utility functions and rail methods.

```julia
using WMATA
WMATA_auth("your subscription key")
#> Authentication complete.
```

# Available Functions
## rail_predictions()
Based on the *Real Time Rail Predictions* methods described in WMATA's documentation [here](https://developer.wmata.com/docs/services/547636a6f9182302184cda78/operations/547636a6f918230da855363f). You can provide a station code or station name.

```
get_rail_predictions(StationCode = "All")
```
Returns a DataFrame of next train arrival information for one or more stations. Will return an empty set of results when no predictions are available. Use All for the StationCodes parameter to return predictions for all stations.

For terminal stations (e.g.: Greenbelt, Shady Grove, etc.), predictions may be displayed twice.

Some stations have two platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center). To retrieve complete predictions for these stations, be sure to pass in both StationCodes.

For trains with no passengers, the DestinationName will be No Passenger.

Next train arrival information is refreshed once every 20 to 30 seconds approximately.

* **Arrival Station:** full name of the station where the train is arriving. 
* **Location Code:** station code for where the train is arriving.
* **Line:** two-letter abbreviation for the line (e.g.: RD, BL, YL, OR, GR, or SV). May also be blank or No for trains with no passengers.
* **Cars:** the Number of cars on a train, usually 6 or 8, but might also return - or NULL.
* **Destination:** abbreviated version of the final destination for a train. This is similar to what is displayed on the signs at stations.
* **Group:** denotes the track this train is on, but does not necessarily equate to Track 1 or Track 2. With the exception of terminal stations, predictions at the same station with different Group values refer to trains on different tracks.
* **Minutes:** minutes until arrival. Can be a numeric value, ARR (arriving), BRD (boarding), ---, or empty.

## get_station_list()
Returns a DataFrame of station location and address information based on a given LineCode. Use `LineCode = "All"` to return all stations. 

*LineCode* - can be "All" or one of the following two-letter abbreviations: 
* RD - Red
* YL - Yellow
* GR - Green
* BL - Blue
* OR - Orange
* SV - Silver

```
station_list(LineCode = "All")
```

The resulting DataFrame includes:

* **StationName:** name of the station.
* **StationCode:** three digit station code. Can be used as an input to `rail_predictions()`.
* **LineCode:** the LineCode of the station.
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

## get_station_timings()

Returns a DataFrame of opening and scheduled first/last train times based on a given StationCode or StationName.

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

## path_between()

Returns a DataFrame of ordered stations and distances between two stations on the same line.

*Note that this method is not suitable on its own as a pathfinding solution between stations.*

```
path_between(FromStationCode = "C13", ToStationCode = "C14")
```
The resulting DataFrame includes: 

* **SequenceNumber:** Ordered sequence number.
* **StationName:** Full name for this station, as shown on the WMATA website.
* **StationCode:** Station code for this station. 
* **LineCode:**	Two-letter abbreviation for the line (e.g.: RD, BL, YL, OR, GR, or SV) this station's platform is on.
* **DistanceToPrev:** Distance in feet to the previous station in the list.

## get_station_to_station()

Returns a DataFrame with the distance, fare information, and estimated travel time between any two stations, including those on different lines. 

Omit both `FromStationCode` and `ToStationCode` to retrieve data for all stations.

```
station_to_station(FromStationCode = "C13", ToStationCode = "C14")
```
The resulting DataFrame includes: 

* **OriginStation:** origin station code.
* **DestinationStation:** destination station code.
* **CompositeMiles:** average of distance traveled between two stations and straight-line distance (as used for WMATA fare calculations). 
* **RailTimes:** destination station code.
* **SeniorRailFare:** reduced fare for senior citizens or people with disabilities.
* **PeakRailFare:** fare during peak times (weekdays from opening to 9:30 AM and 3-7 PM, and weekends from midnight to closing).
* **OffPeakRailFare:** fare during off-peak times (times other than the ones described below).

## get_train_positions()

Returns uniquely identifiable trains in service and what track circuits they currently occupy. Will return an empty set of results when no positions are available.

Data is refreshed once every 7-10 seconds.

**CarCount:** number of cars. Can sometimes be 0 when there is no data available.
**CircuitId:**	the circuit identifier the train is currently on. This identifier can be referenced from the Standard Routes method.
**DestinationStationCode:**	destination station code. Can be NULL. Use this value in other rail-related APIs to retrieve data about a station. Note **that this value may sometimes differ from the destination station code returned by our Next Trains methods.
**DirectionNum:** the direction of movement regardless of which track the train is on. Valid values are 1 or 2. Generally speaking, trains with direction 1 are northbound/eastbound, while trains with direction 2 are southbound/westbound.
**LineCode:** two-letter abbreviation for the line (e.g.: RD, BL, YL, OR, GR, or SV). May also be NULL in certain cases.
**SecondsAtLocation:** approximate "dwell time". This is not an exact value, but can be used to determine how long a train has been reported at the same track circuit.
**ServiceType:** Service Type of a train, can be any of the following Service Types
**TrainId:** uniquely identifiable internal train identifier.
**TrainNumber:** non-unique train identifier, often used by WMATA's Rail Scheduling and Operations Teams, as well as over open radio communication.
**Service Types:**
- *NoPassengers:* This is a non-revenue train with no passengers on board. Note that this designation of NoPassengers does not necessarily correlate with PIDS "No Passengers". As of 08/22/2016, this functionality has been reinstated to include all non-revenue vehicles, with minor exceptions.
- *Normal:*	this is a normal revenue service train.
- *Special:* this is a special revenue service train with an unspecified line and destination. This is more prevalent during scheduled track work.
- *Unknown:* this often denotes cases with unknown data or work vehicles.