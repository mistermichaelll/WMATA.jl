include("utils.jl")

function get_station_list(;LineCode::String = "All", IncludeAdditionalInfo::Bool = false)
    LineCode = verify_line_input(LineCode)

    if LineCode == "All"
        url = wmata.station_list_url
    else
        url = wmata.station_list_url * "?LineCode=" * LineCode
    end

    r = wmata_request(url)

    # unnest the "Address" column
    station_list_raw = DataFrame(r["Stations"])
    addresses = station_list_raw[!, :Address] |> DataFrame

    station_list = hcat(
        select(station_list_raw, Not([:Address, :LineCode4])),
        addresses
    )

    return station_list
end

function get_rail_predictions(;StationCode::String = "All", StationName::String = "")
    if StationName != ""
        StationCode = get_station_code(StationName)
    else
        verify_station_input(StationCode)
    end

    url = wmata.rail_predictions_url * StationCode * "/"

    r = wmata_request(url)

    rail_predictions = DataFrame(r["Trains"])

    return rail_predictions
end

function get_path_between(;FromStationCode::String, ToStationCode::String)
    FromStationCode = verify_station_input(FromStationCode)
    ToStationCode = verify_station_input(ToStationCode)

    url = wmata.paths_url * "FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode

    r = wmata_request(url)

    response_elements = [
        "SeqNum",
        "StationName",
        "StationCode",
        "LineCode",
        "DistanceToPrev"
    ]

    paths_between = DataFrame(
        map(
        id_col -> (id_col => [r["Path"][path_point][id_col] for path_point in 1:length(r["Path"])]),
        response_elements
        )
    )

    if nrow(paths_between) == 0
        @error "No path between stations. Did you choose stations on the same line?"
    else
        return paths_between
    end
end

function get_station_to_station(;FromStationCode::String = "", ToStationCode::String = "")
    if (FromStationCode == "" && ToStationCode == "")
        url = wmata.station_to_station_url
    else
        url = wmata.station_to_station_url * "?FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    end

    r = wmata_request(url)

    response_elements = [
        "SourceStation",
        "DestinationStation",
        "CompositeMiles",
        "RailTime",
        "SeniorDisabled",
        "PeakTime",
        "OffPeakTime"
    ]

    return DataFrame(
       map(response_elements) do id_col
        if id_col in ["SeniorDisabled", "PeakTime", "OffPeakTime"]
            (id_col => [r["StationToStationInfos"][num]["RailFare"][id_col] for num in 1:length(r["StationToStationInfos"])])
        else
            (id_col => [r["StationToStationInfos"][num][id_col] for num in 1:length(r["StationToStationInfos"])])
        end
        end
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
        map(
        id_col -> (id_col => [train[id_col] for train in train_positions]),
        response_elements
        )
    )
end

function get_rail_incidents()
    r = wmata_request(wmata.rail_incidents_url)

    response_elements = [
    "IncidentID",
    "Description",
    "EndLocationFullName",
    "PassengerDelay",
    "LinesAffected",
    "IncidentType",
    "DateUpdated"
    ]

    DataFrame(
        map(response_elements) do id_col
        if id_col == "LinesAffected"
            lines_affected = [r["Incidents"][incident][id_col] for incident in 1:length(r["Incidents"])]
            ("LinesAffected" => map(x -> split(replace(x, " " => ""), ';', keepempty = false), lines_affected))
        else
            (id_col => [r["Incidents"][incident][id_col] for incident in 1:length(r["Incidents"])])
        end
        end
    )
end
