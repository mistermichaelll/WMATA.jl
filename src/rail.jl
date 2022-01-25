#=
==========================================
                RAIL
==========================================
This contains functions for getting information about WMATA's rail (Metro) stations.

Given that WMATA's API has methods for buses as well – I thought it may make sense to split 
those up this way.
=#

#= 
Function Name: station_list 
Description: Returns a dataframe of station location and address information based on a given LineCode. 
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

    subscription_key = Dict("api_key" => WMATA_AuthToken)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # get the basic station elements
    name = [station["Name"] for station = r["Stations"]]
    station_code = [station["Code"] for station = r["Stations"]]
    # additional line codes
    line_code_2 = [station["LineCode2"] for station = r["Stations"]]
    line_code_3 = [station["LineCode3"] for station = r["Stations"]]
    line_code_4 = [station["LineCode4"] for station = r["Stations"]]
    # station together 1
    station_together_1 = [station["StationTogether1"] for station = r["Stations"]]
    # lat/long
    lat = [station["Lat"] for station = r["Stations"]]
    long = [station["Lon"] for station = r["Stations"]]
    # address elements of the station 
    city = [station["Address"][:"City"] for station = r["Stations"]]
    state = [station["Address"][:"State"] for station = r["Stations"]]
    street = [station["Address"][:"Street"] for station = r["Stations"]]
    zip = [station["Address"][:"Zip"] for station = r["Stations"]]

    #= currently not in use, according to API doc.

     for station in r["Stations"] 
         push!(station_together_2, station["StationTogether2"])
     end

    =# 

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
Description: Returns opening and scheduled first/last train times based on a given StationCode.

Note that for stations with multiple platforms (e.g.: Metro Center, L'Enfant Plaza, etc.), a distinct call is required for each StationCode to retrieve the full set of train times at such stations. 
=#
function station_timings(;StationCode::String)
    if StationCode == "" 
        ArgumentError("Please select a single station code.")
    else 
        url = "https://api.wmata.com/Rail.svc/json/jStationTimes" * "?StationCode=" * StationCode
    end
    
    subscription_key = Dict("api_key" => WMATA_AuthToken)
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
        @warn "No First/Last train information available."
        d_c = "DROP"
    end

    if d_c != "DROP"
        first_trains_destinations = []
        first_trains_times = []
        last_trains_destinations = []
        last_trains_times = []

        for i in days_of_week
            push!(first_trains_destinations, r["StationTimes"][:1][i]["FirstTrains"][:1]["DestinationStation"])
            push!(first_trains_times, r["StationTimes"][:1][i]["FirstTrains"][:1]["Time"])
            push!(last_trains_destinations, r["StationTimes"][:1][i]["LastTrains"][:1]["DestinationStation"])
            push!(last_trains_times, r["StationTimes"][:1][i]["LastTrains"][:1]["Time"])
        end

    else 
        # fill out the columns that are missing but in a familiar fashion.
        first_trains_destinations = ["--", "--", "--", "--", "--", "--", "--"]
        first_trains_times = ["--", "--", "--", "--", "--", "--", "--"]
        last_trains_times = ["--", "--", "--", "--", "--", "--", "--"]
        last_trains_destinations = ["--", "--", "--", "--", "--", "--", "--"] 
    end

    station_timings = DataFrame("StationName" => station_name, "StationCode" => station_code, "DayOfWeek" => days_of_week, 
    "OpeningTime" => opening_times, "FirstTrainDestination" => first_trains_destinations, "FirstTrainTime" => first_trains_times, 
    "LastTrainDestination" => last_trains_destinations, "LastTrainTime" => last_trains_times)

    station_timings
end

#=
Function Name: rail_predictions()
Description: This function returns a dataframe with next train arrival information for one or more stations. 
Will return an empty set of results when no predictions are available. 
Use All for the StationCodes parameter to return predictions for all stations (this is default).

For terminal stations (e.g.: Greenbelt, Shady Grove, etc.), predictions may be displayed twice.

Some stations have two platforms (e.g.: Gallery Place, Fort Totten, L'Enfant Plaza, and Metro Center). To retrieve complete predictions for these stations, be sure to pass in both StationCodes.

For trains with no passengers, the DestinationName will be No Passenger.

Next train arrival information is refreshed once every 20 to 30 seconds approximately.
=#
function rail_predictions(;StationCode::String = "All")
    # get the station object for the station that we are calling in the function
    url = "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/" * StationCode * "/"
    subscription_key = Dict("api_key" => WMATA_AuthToken)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # create the columns that will make up our dataframe
    lines = [station["Line"] for station = r["Trains"]]
    destination = [String(station["Destination"]) for station = r["Trains"]]
    group = [station["Group"] for station = r["Trains"]]
    location = [String(station["LocationName"]) for station = r["Trains"]]
    location_code = [String(station["LocationCode"]) for station = r["Trains"]]
    mins = [station["Min"] for station = r["Trains"]]
    cars = [station["Car"] for station = r["Trains"]]

    # create dataframe and 
    # return it from function
    # -----------------------
    rail_predictions = DataFrame("Arrival Station" => location, "Location Code" => location_code, "Line" => lines, "Cars" => cars, "Destination" => destination, "Group" => group, "Minutes" => mins)

    rail_predictions
end

#=
Function Name: path_between()

Returns a set of ordered stations and distances between two stations on the same line.

Note that this method is not suitable on its own as a pathfinding solution between stations.
=#
function path_between(;FromStationCode::String, ToStationCode::String)
    url = "https://api.wmata.com/Rail.svc/json/jPath?" * "FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    subscription_key = Dict("api_key" => WMATA_AuthToken)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))

    # define vectors for us to push info to
    # -------------------------------------
    seq_nums = [] 
    station_names = []
    station_codes = []
    line_codes = []
    distances_to_prev = []

    # get the vectors of information, these 
    # will be in order of sequence.
    # -------------------------------------
    for path_point in 1:length(r["Path"])
        push!(seq_nums, r["Path"][path_point]["SeqNum"])
        push!(station_names, r["Path"][path_point]["StationName"])
        push!(station_codes, r["Path"][path_point]["StationCode"])
        push!(line_codes, r["Path"][path_point]["LineCode"])
        push!(distances_to_prev, r["Path"][path_point]["DistanceToPrev"])
    end

    # check if user has input stations which are on the same line.
    if length(seq_nums) == 0 & length(station_names) == 0
        @error "No path between stations. Did you choose stations on the same line?"
    else 
        paths = DataFrame("SequenceNumber" => seq_nums, "StationName" => station_names, "StationCode" => station_codes, 
        "LineCode" => line_codes, "DistanceToPrevious" => distances_to_prev)
        paths 
    end
end

#=
Function Name: station_to_station()

Returns a distance, fare information, and estimated travel time between any two stations, including those on different lines. 
Omit both parameters to retrieve data for all stations.
=# 
function station_to_station(;FromStationCode::String = "", ToStationCode::String = "")
    if (FromStationCode == "" && ToStationCode == "")
        url = "https://api.wmata.com/Rail.svc/json/jSrcStationToDstStationInfo"
    else
        url = "https://api.wmata.com/Rail.svc/json/jSrcStationToDstStationInfo?" * "FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    end
    subscription_key = Dict("api_key" => WMATA_AuthToken)
    r = request("GET", url, subscription_key)
    r = parse(String(r.body))
    # ----------------------------------------
    origin_stations = [] 
    destination_stations = []
    composite_miles = [] 
    rail_times = [] 
    senior_rail_fare = [] 
    peak_rail_fare = [] 
    off_peak_rail_fare = []
    # ----------------------------------------
    for i in 1:length(r["StationToStationInfos"])
        push!(origin_stations, r["StationToStationInfos"][i]["SourceStation"])
        push!(destination_stations, r["StationToStationInfos"][i]["DestinationStation"])
        push!(composite_miles, r["StationToStationInfos"][i]["CompositeMiles"])
        push!(rail_times, r["StationToStationInfos"][i]["RailTime"])
        push!(senior_rail_fare, r["StationToStationInfos"][i]["RailFare"]["SeniorDisabled"])
        push!(peak_rail_fare, r["StationToStationInfos"][i]["RailFare"]["PeakTime"])
        push!(off_peak_rail_fare, r["StationToStationInfos"][i]["RailFare"]["OffPeakTime"])
    end 
    # ----------------------------------------
    station_to_station = DataFrame("OriginStation" => origin_stations, "DestinationStation" => destination_stations, "CompositeMiles" => composite_miles, 
    "RailTimes" => rail_times, "SeniorRailFare" => senior_rail_fare, "PeakRailFare" => peak_rail_fare, "OffPeakRailFare" => off_peak_rail_fare)
    
    station_to_station
end
