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
function station_list(SubscriptionKey::String, LineCode::String = ""; IncludeAdditionalInfo::Bool = false)
    # need additiona info if LineCode is included vs. if it is not.
    if LineCode == "" 
        url = "https://api.wmata.com/Rail.svc/json/jStations"
    else 
        url = "https://api.wmata.com/Rail.svc/json/jStations" * "?LineCode=" * LineCode
    end
    subscription_key = Dict("api_key" => SubscriptionKey)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # get the basic station elements
    name = []
    station_code = []
    lat = []
    long = []

    # additional station elements dataframe will optionally include
    station_together_1 = []
    station_together_2 = []
    line_code_2 = []
    line_code_3 = []
    line_code_4 = []

    for station in r["Stations"] 
        push!(name, station["Name"])
    end

    for station in r["Stations"] 
        push!(station_code, station["Code"])
    end

    # this will return the station addresses in a dictionary. 
    # I've chosen to split them into coulumns.
    # -------------------------------------------------------
    # for station in r["Stations"] 
    #     push!(address, station["Address"])
    # end

    for station in r["Stations"] 
        push!(lat, station["Lat"])
    end

    for station in r["Stations"] 
        push!(long, station["Lon"])
    end

    # stations together
    for station in r["Stations"] 
        push!(station_together_1, station["StationTogether1"])
    end
    # currently not in use, according to API doc.
    # for station in r["Stations"] 
    #     push!(station_together_2, station["StationTogether2"])
    # end

    # additional line codes
    for station in r["Stations"] 
        push!(line_code_2, station["LineCode2"])
    end
    for station in r["Stations"] 
        push!(line_code_3, station["LineCode3"])
    end
    for station in r["Stations"] 
        push!(line_code_4, station["LineCode4"])
    end


    # get the address elements of the stations
    # ----------------------------------------
    city = []
    state = []
    street = []
    zip = []

    for station in r["Stations"]
        push!(city, station["Address"][:"City"])
    end

    for station in r["Stations"]
        push!(state, station["Address"][:"State"])
    end

    for station in r["Stations"]
        push!(street, station["Address"][:"Street"])
    end

    for station in r["Stations"]
        push!(zip, station["Address"][:"Zip"])
    end

    if IncludeAdditionalInfo == true
        station_info = DataFrame("StationName" => name, "StationCode" => station_code, 
        # -------------------------------------------------------------------------------------------
        # additional information returned if requested
        "StationTogether1" => station_together_1, 
        # "StationTogether2" => station_together_2, 
        "LineCode2" => line_code_2, "LineCode3" => line_code_3, "LineCode4" => line_code_4,
        # -------------------------------------------------------------------------------------------
        "Latitude" => lat, "Longitude" => long, "City" => city, "State" => state, "Street" => street, "Zip" => zip)
    else 
        station_info = DataFrame("StationName" => name, "StationCode" => station_code, "Latitude" => lat, 
        "Longitude" => long, "City" => city, "State" => state, "Street" => street, "Zip" => zip)
    end

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