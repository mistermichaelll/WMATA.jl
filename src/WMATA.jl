module WMATA
include("authentication.jl")

import DataFrames.DataFrame, JSON.parse, HTTP.request
export rail_predictions, station_list, station_timings, WMATA_auth

#= 
Function Name: station_list 
Purpose: Returns a dataframe of station location and address information based on a given LineCode. 
Arguments:
    1) LineCode - can be empty or one of the following two-letter abbreviations: 
        RD - Red
        YL - Yellow
        GR - Green
        BL - Blue
        OR - Orange
        SV - Silver
=#
function station_list(;LineCode::String = "", IncludeAdditionalInfo::Bool = false)
    # need additional info if LineCode is included vs. if it is not.
    if LineCode == "All" 
        url = "https://api.wmata.com/Rail.svc/json/jStations"
    else 
        url = "https://api.wmata.com/Rail.svc/json/jStations" * "?LineCode=" * LineCode
    end

    subscription_key = Dict("api_key" => AuthToken)
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
Function Name: station_timings
Returns opening and scheduled first/last train times based on a given StationCode.

Note that for stations with multiple platforms (e.g.: Metro Center, L'Enfant Plaza, etc.), a distinct call is required for each StationCode to retrieve the full set of train times at such stations. 
=#
function station_timings(;StationCode::String)
    if StationCode == "" 
        ArgumentError("Please select a single station code.")
    else 
        url = "https://api.wmata.com/Rail.svc/json/jStationTimes" * "?StationCode=" * StationCode
    end
    
    subscription_key = Dict("api_key" => AuthToken)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # define the days of the week
    days_of_week = ["Sunday" ,"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    # station name/code are constant values which we can pull from the API response
    station_name = r["StationTimes"][1]["StationName"]
    station_code = r["StationTimes"][1]["Code"]

    opening_times = []
    for i in days_of_week 
        push!(opening_times, r["StationTimes"][1][i]["OpeningTime"])
    end

    #= 
    from messing about in the API, there are cases where first/last train info is coming back empty and 
    resulting in an out of bounds error in Julia. I'm setting a drop condition (d_c) so that if these 
    successfully run, the function will return the full dataframe. Otherwise, first/last train info 
    will be blank.
    =#
    d_c = "OK"
    try 
        first_trains_destinations = []
        for i in days_of_week
            push!(first_trains_destinations, r["StationTimes"][:1][i]["FirstTrains"][:1]["DestinationStation"])
        end
    catch 
        @warn "No First/Last train information. Please check the incident report for this station."
        d_c = "DROP"
    end

    if d_c != "DROP"
        first_trains_destinations = []
        for i in days_of_week
            push!(first_trains_destinations, r["StationTimes"][:1][i]["FirstTrains"][:1]["DestinationStation"])
        end

        first_trains_times = []
        for i in days_of_week 
            push!(first_trains_times, r["StationTimes"][:1][i]["FirstTrains"][:1]["Time"])
        end

        last_trains_times = []
        for i in days_of_week 
            push!(last_trains_times, r["StationTimes"][:1][i]["LastTrains"][:1]["Time"])
        end

        last_trains_times = []
        for i in days_of_week 
            push!(last_trains_times, r["StationTimes"][:1][i]["LastTrains"][:1]["Time"])
        end
    else 
        # fill out the columns that are missing but in a familiar fashion.
        first_trains_destinations = ["--", "--", "--", "--", "--", "--", "--"]
        first_trains_times = ["--", "--", "--", "--", "--", "--", "--"]
        last_trains_times = ["--", "--", "--", "--", "--", "--", "--"]
        last_trains_times = ["--", "--", "--", "--", "--", "--", "--"] 
    end

    station_timings = DataFrame("StationName" => station_name, "StationCode" => station_code, "DayOfWeek" => days_of_week, 
    "OpeningTime" => opening_times, "FirstTrainDestination" => first_trains_destinations, "FirstTrainTime" => first_trains_times, 
    "LastTrainDestination" => first_trains_destinations, "LastTrainTime" => first_trains_times)

    station_timings
end

#=
This function returns a dataframe with next train arrival information for one or more stations. Will return an empty set of results when no predictions are available. 
Use All for the StationCodes parameter to return predictions for all stations (this is default).

For terminal stations (e.g.: Greenbelt, Shady Grove, etc.), predictions may be displayed twice.

Some stations have two platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center). To retrieve complete predictions for these stations, be sure to pass in both StationCodes.

For trains with no passengers, the DestinationName will be No Passenger.

Next train arrival information is refreshed once every 20 to 30 seconds approximately.
=#
function rail_predictions(;StationCode::String = "All")
    url = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/" * StationCode * "/"
    subscription_key = Dict("api_key" => AuthToken)
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