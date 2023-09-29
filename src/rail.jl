include("utils.jl")

"""
    get_station_list()

Returns a list of station location and address information based on a given LineCode. Omit the LineCode to return all stations.

```julia-repl
julia> get_station_list(; LineCode = "YL")
```
"""
function get_station_list(;LineCode::String = "All")
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

"""
    get_rail_predictions()

Returns next train arrival information for one or more stations. Will return an empty DataFrame of results when no predictions are available.

Use "All" for the StationCode parameter to return predictions for all stations.
"""
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

    return r[:Path] |> DataFrame
end

function get_station_to_station(;FromStationCode::String = "", ToStationCode::String = "")
    if (FromStationCode == "" && ToStationCode == "")
        url = wmata.station_to_station_url
    else
        url = wmata.station_to_station_url * "?FromStationCode=" * FromStationCode * "&" * "ToStationCode=" * ToStationCode
    end

    r = wmata_request(url)[:StationToStationInfos]

    main_cols = [:SourceStation, :DestinationStation, :CompositeMiles, :RailTime]

    df_a = DataFrame(; (col => [r[i][col] for i in eachindex(r)] for col in main_cols)...)
    # rail fare is basically a nested JSON object, split it out and make it separate columns.
    df_b = DataFrame([r[i][:RailFare] for i in eachindex(r)])

    return hcat(df_a, df_b)
end

function get_train_positions()
    r = wmata_request(wmata.train_positions_url)

    return r[:TrainPositions] |> DataFrame
end

function get_rail_incidents()
    r = wmata_request(wmata.rail_incidents_url)

    return r[:Incidents] |> DataFrame
end
