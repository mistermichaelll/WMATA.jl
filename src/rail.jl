include("utils.jl")

function station_list(;LineCode::String = "All", IncludeAdditionalInfo::Bool = false)
    LineCode = verify_line_input(LineCode)

    if LineCode == "All" 
        url = wmata.station_list_url
    else 
        url = wmata.station_list_url * "?LineCode=" * LineCode
    end

    r = wmata_request(url)

    response_elements = [
        "Name", 
        "Code", 
        "LineCode1",
        "Lat", 
        "Lon", 
        "City", 
        "State", 
        "Street", 
        "Zip"
    ]

    if IncludeAdditionalInfo == true 
        append!(
            response_elements,
            ["LineCode2", 
            "LineCode3", 
            "LineCode4", 
            "StationTogether1"]
        )
    else 
        response_elements 
    end
    
    # function we can map to the response elements to efficiently construct 
    #  our dataframe!
    function station_list_constructor(id_col::String)
        address_element = ["City", "State", "Street", "Zip"]

        if id_col in address_element 
            (id_col => [station["Address"][id_col] for station in r["Stations"]])
        else 
            (id_col => [station[id_col] for station in r["Stations"]])
        end 
    end

    station_list = DataFrame(
        map(station_list_constructor, response_elements)
        )

    # rename some columns to be clearer
    new_names = Dict(
        "Name" => "StationName", 
        "Code" => "StationCode",
        "LineCode1" => "LineCode", 
        "Lat" => "Latitude", 
        "Lon" => "Longitude" 
    )

    for og_name in keys(new_names)
        rename!(station_list, Symbol(og_name) => Symbol(new_names[og_name]))
    end

    return station_list
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

    rail_predictions = DataFrame(
        map(id_col -> (id_col => [station[id_col] for station in r["Trains"]]), 
        response_elements
        )
    )
        
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

    return DataFrame(
        map(id_col -> (id_col => [train[id_col] for train in train_positions]),
        response_elements
        )
    )
end
