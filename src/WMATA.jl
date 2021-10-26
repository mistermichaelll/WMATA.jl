module WMATA

import DataFrames.DataFrame, JSON.parse, HTTP.request

function station_list(sub_key::String, LineCode::String)
    #= 
    Returns a dataframe of station location and address information based on a given LineCode. Omit the LineCode to return all stations. 
    =#
    url = "https://api.wmata.com/Rail.svc/json/jStations" * LineCode # LineCode can be empty
    subscription_key = Dict("api_key" => sub_key)
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
    for i in test_me["Stations"] 
        push!(name, i["Name"])
    end

    for i in test_me["Stations"] 
        push!(station_code, i["Code"])
    end

    for i in test_me["Stations"] 
        push!(address, i["Address"])
    end

    for i in test_me["Stations"] 
        push!(lat, i["Lat"])
    end

    for i in test_me["Stations"] 
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

function rail_predictions(sub_key::String, station_id::String)
    #=
    This function returns a dataframe with next train arrival information for one or more stations. Will return an empty set of results when no predictions are available. 
    Use All for the StationCodes parameter to return predictions for all stations.

    For terminal stations (e.g.: Greenbelt, Shady Grove, etc.), predictions may be displayed twice.

    Some stations have two platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center). To retrieve complete predictions for these stations, be sure to pass in both StationCodes.

    For trains with no passengers, the DestinationName will be No Passenger.

    Next train arrival information is refreshed once every 20 to 30 seconds approximately.
    =#
    url = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/" * station_id * "/"
    subscription_key = Dict("api_key" => sub_key)
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
    rail_predictions = DataFrame("Arrival Station" => location, "Location Code" => location_code, "Lines" => lines, "Cars" => cars, "Destination" => destination, "Group" => group, "Minutes" => mins)

    rail_predictions
end


end # module