module WMATA

import DataFrames.DataFrame, JSON.parse, HTTP.request

export rail_predictions, station_list

#= 
Function Name: station_list 
Purpose: Returns a dataframe of station location and address information based on a given LineCode. 
Arguments:
    1) SubscriptionKey - subscription key from WMATA's API. I recommend defining this as a constant at the start of your script.
    2) LineCode - can be empty or one of the following two-letter abbreviations: 
        RD - Red
        YL - Yellow
        GR - Green
        BL - Blue
        OR - Orange
        SV - Silver
=#
function station_list(SubscriptionKey::String, LineCode::String = "")
    if LineCode == "" 
        url = "https://api.wmata.com/Rail.svc/json/jStations"
    else 
        url = "https://api.wmata.com/Rail.svc/json/jStations" * "?LineCode=" * LineCode
    end
    subscription_key = Dict("api_key" => SubscriptionKey)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))
    #= 
    TODO: STATION elements
    ---------------------- 
    address, code, lat, long, linecode1, linecode2, linecode3, linecode4, name, 
    stationtogether1, stationtogether2
    =#
    name = []
    station_code = []
    address = []
    lat = []
    long = []
    for i in r["Stations"] 
        push!(name, i["Name"])
    end

    for i in r["Stations"] 
        push!(station_code, i["Code"])
    end

    for i in r["Stations"] 
        push!(address, i["Address"])
    end

    for i in r["Stations"] 
        push!(lat, i["Lat"])
    end

    for i in r["Stations"] 
        push!(long, i["Lon"])
    end


    #= 
    TODO: Address Elements 
    ----------------------
    city, state, street, zip
    =#
    station_info = DataFrame("StationName" => name, "StationCode" => station_code, "Address" => address, "Latitude" => lat, "Longitude" => long)

    station_info

end

#=
This function returns a dataframe with next train arrival information for one or more stations. Will return an empty set of results when no predictions are available. 
Use All for the StationCodes parameter to return predictions for all stations (this is default).

For terminal stations (e.g.: Greenbelt, Shady Grove, etc.), predictions may be displayed twice.

Some stations have two platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center). To retrieve complete predictions for these stations, be sure to pass in both StationCodes.

For trains with no passengers, the DestinationName will be No Passenger.

Next train arrival information is refreshed once every 20 to 30 seconds approximately.
=#
function rail_predictions(SubscriptionKey::String, station_id::String = "All")
    url = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/" * station_id * "/"
    subscription_key = Dict("api_key" => SubscriptionKey)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # define empty lists for parsing json
    # -----------------------------------
    lines = []
    destination = []
    group = []
    mins = [] 
    location = []
    location_code = []
    cars = []
    # create the lists that make up our dataframe 
    # -------------------------------------------
    for i in r["Trains"]
        push!(lines, i["Line"])
    end
    for i in r["Trains"]
        push!(destination, String(i["Destination"]))
    end
    for i in r["Trains"]
        push!(group, i["Group"])
    end
    for i in r["Trains"]
        push!(location, String(i["LocationName"]))
    end
    for i in r["Trains"]
        push!(location_code, String(i["LocationCode"]))
    end
    for i in r["Trains"]
        push!(mins ,i["Min"])
    end
    for i in r["Trains"]
        push!(cars ,i["Car"])
    end
    # create dataframe and 
    # return it from function
    # -----------------------
    rail_predictions = DataFrame("Arrival Station" => location, "Location Code" => location_code, "Line" => lines, "Cars" => cars, "Destination" => destination, "Group" => group, "Minutes" => mins)

    rail_predictions
end

end # module