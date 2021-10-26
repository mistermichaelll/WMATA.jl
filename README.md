# WMATA.jl
Julia package which simplifies the process of interacting with WMATA's public API. You will need an API key from WMATA. 

# Available Functions
## *rail_predictions*
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
