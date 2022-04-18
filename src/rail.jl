include("utils.jl")

function station_list(;LineCode::String = "All", IncludeAdditionalInfo::Bool = false)
    LineCode = verify_line_input(LineCode)

    if LineCode == "All" 
        url = wmata.station_list_url
    else 
        url = wmata.station_list_url * "?LineCode=" * LineCode
    end

    r = wmata_request(url)

    name = [station["Name"] for station in r["Stations"]]
    station_code = [station["Code"] for station in r["Stations"]]
    line_code_1 = [station["LineCode1"] for station in r["Stations"]]
    line_code_2 = [station["LineCode2"] for station in r["Stations"]]
    line_code_3 = [station["LineCode3"] for station in r["Stations"]]
    line_code_4 = [station["LineCode4"] for station in r["Stations"]]
    station_together_1 = [station["StationTogether1"] for station in r["Stations"]]
    lat = [station["Lat"] for station in r["Stations"]]
    long = [station["Lon"] for station in r["Stations"]]
    city = [station["Address"][:"City"] for station in r["Stations"]]
    state = [station["Address"][:"State"] for station in r["Stations"]]
    street = [station["Address"][:"Street"] for station in r["Stations"]]
    zip = [station["Address"][:"Zip"] for station in r["Stations"]]

    if IncludeAdditionalInfo == true
        return DataFrame(
            "StationName" => name, 
            "LineCode" => LineCode, 
            "StationCode" => station_code, 
            "StationTogether1" => station_together_1,
            "LineCode" => line_code_1, 
            "LineCode2" => line_code_2, 
            "LineCode3" => line_code_3, 
            "LineCode4" => line_code_4,
            "Latitude" => lat, 
            "Longitude" => long, 
            "City" => city, 
            "State" => state, 
            "Street" => street, 
            "Zip" => zip
            )
    else 
        return DataFrame(
            "StationName" => name, 
            "StationCode" => station_code,
            "LineCode" => line_code_1, 
            "Latitude" => lat, 
            "Longitude" => long, 
            "City" => city, 
            "State" => state, 
            "Street" => street, 
            "Zip" => zip
        )
    end
end

function station_timings(;StationCode::String = "", StationName::String = "")
    if StationName != ""
        StationCode = get_station_code(StationName)
    else 
        verify_station_input(StationCode)
    end 

    url = wmata.station_timings_url * "?StationCode=" * StationCode
    
    r = wmata_request(url)

    days_of_week = ["Sunday" ,"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    station_name = r["StationTimes"][1]["StationName"]
    station_code = r["StationTimes"][1]["Code"]

    opening_times = [r["StationTimes"][1][day]["OpeningTime"] for day in days_of_week]
    #= 
    from messing about in the API, there are cases where first/last train info is coming back empty and 
    resulting in an out of bounds error in Julia. I'm setting a drop condition so that if these 
    successfully run, the function will return the full dataframe. Otherwise, first/last train info 
    will be blank.
    =#
    drop_condition = "OK"
    try 
        first_trains_destinations = [r["StationTimes"][:1][day]["FirstTrains"][:1]["DestinationStation"] for day in days_of_week]
    catch 
        @warn "No First/Last train information available."
        drop_condition = "DROP"
    end

    if drop_condition != "DROP"
        first_trains_destinations = [r["StationTimes"][:1][day]["FirstTrains"][:1]["DestinationStation"] for day in days_of_week]
        first_trains_times = [r["StationTimes"][:1][day]["FirstTrains"][:1]["Time"] for day in days_of_week]
        last_trains_destinations = [r["StationTimes"][:1][day]["LastTrains"][:1]["DestinationStation"] for day in days_of_week]
        last_trains_times = [r["StationTimes"][:1][day]["LastTrains"][:1]["Time"] for day in days_of_week]
    else 
        first_trains_destinations = ["--" for day in days_of_week]
        first_trains_times = ["--" for day in days_of_week]
        last_trains_times = ["--" for day in days_of_week]
        last_trains_destinations = ["--" for day in days_of_week]
    end

    return DataFrame(
        "StationName" => station_name, 
        "StationCode" => station_code, 
        "DayOfWeek" => days_of_week, 
        "OpeningTime" => opening_times, 
        "FirstTrainDestination" => first_trains_destinations, 
        "FirstTrainTime" => first_trains_times, 
        "LastTrainDestination" => last_trains_destinations, 
        "LastTrainTime" => last_trains_times
        )
end

function rail_predictions(;StationCode::String = "All", StationName::String = "")
    if StationName != ""
        StationCode = get_station_code(StationName)
    else 
        verify_station_input(StationCode)
    end 

    url = wmata.rail_predictions_url * StationCode * "/"

    r = wmata_request(url)

    response_elements = [
        "LocationName", 
        "LocationCode",
        "Line", 
        "Car",
        "Destination", 
        "Group",  
        "Min" 
    ]

    rail_predictions_constructor(id_col::String) = (id_col => [station[id_col] for station in r["Trains"]])

    rail_predictions = DataFrame(map(rail_predictions_constructor, response_elements))
    rename!(rail_predictions, :LocationName => :ArrivalStation)
    rail_predictions[!, :Min] = convert_arrival_times(rail_predictions[!, :Min])

    return rail_predictions
end

function path_between(;FromStationCode::String, ToStationCode::String)
    FromStationCode = verify_station_input(FromStationCode)
    ToStationCode = verify_station_input(ToStationCode)

    url = wmata.paths_url * "FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    
    r = wmata_request(url)

    seq_nums = [r["Path"][path_point]["SeqNum"] for path_point in 1:length(r["Path"])]
    station_names = [r["Path"][path_point]["StationName"] for path_point in 1:length(r["Path"])]
    station_codes = [r["Path"][path_point]["StationCode"] for path_point in 1:length(r["Path"])]
    line_codes = [r["Path"][path_point]["LineCode"] for path_point in 1:length(r["Path"])]
    distances_to_prev = [r["Path"][path_point]["DistanceToPrev"] for path_point in 1:length(r["Path"])]

    # check if user has input stations which are on the same line.
    if length(seq_nums) == 0 & length(station_names) == 0
        @error "No path between stations. Did you choose stations on the same line?"
    else 
        return DataFrame(
            "SequenceNumber" => seq_nums, 
            "StationName" => station_names, 
            "StationCode" => station_codes, 
            "LineCode" => line_codes,
            "DistanceToPrevious" => distances_to_prev
            )
    end
end

function station_to_station(;FromStationCode::String = "", ToStationCode::String = "")
    FromStationCode = verify_station_input(FromStationCode)
    ToStationCode = verify_station_input(ToStationCode)

    if (FromStationCode == "" && ToStationCode == "")
        url = wmata.station_to_station_url
    else
        url = wmata.station_to_station_url * "?FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    end

    r = wmata_request(url)

    origin_stations = [r["StationToStationInfos"][num]["SourceStation"] for num in 1:length(r["StationToStationInfos"])]
    destination_stations = [r["StationToStationInfos"][num]["DestinationStation"] for num in 1:length(r["StationToStationInfos"])]
    composite_miles = [r["StationToStationInfos"][num]["CompositeMiles"] for num in 1:length(r["StationToStationInfos"])] 
    rail_times = [r["StationToStationInfos"][num]["RailTime"] for num in 1:length(r["StationToStationInfos"])] 
    senior_rail_fare = [r["StationToStationInfos"][num]["RailFare"]["SeniorDisabled"] for num in 1:length(r["StationToStationInfos"])] 
    peak_rail_fare = [r["StationToStationInfos"][num]["RailFare"]["PeakTime"] for num in 1:length(r["StationToStationInfos"])] 
    off_peak_rail_fare = [r["StationToStationInfos"][num]["RailFare"]["OffPeakTime"] for num in 1:length(r["StationToStationInfos"])]

    return DataFrame(
        "OriginStation" => origin_stations, 
        "DestinationStation" => destination_stations, 
        "CompositeMiles" => composite_miles, 
        "RailTimes" => rail_times, 
        "SeniorRailFare" => senior_rail_fare, 
        "PeakRailFare" => peak_rail_fare, 
        "OffPeakRailFare" => off_peak_rail_fare
        )
end

function get_train_positions() 
    r = wmata_request(wmata.train_positions_url)
    train_positions = r["TrainPositions"]

    response_elements = [
    "CarCount", 
    "DestinationStationCode",
    "DirectionNum", 
    "LineCode",	
    "SecondsAtLocation",	
    "ServiceType",	
    "TrainId",
    "TrainNumber",
    "CircuitId"
    ]

    train_position_constructor(id_col::String) = (id_col => [train[id_col] for train in train_positions])

    return DataFrame(
        map(train_position_constructor, response_elements)
        )
end
