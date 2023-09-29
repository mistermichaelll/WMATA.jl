# wrapper for API requests.
function wmata_request(url::String)
    subscription_key = Dict("api_key" => wmata.api_key)
    api_response = JSON3.read(request("GET", url, subscription_key).body)

    return api_response
end

# verify that a linecode is one that makes sense
function verify_line_input(line_input)
    line_colors = ["RD", "BL", "YL", "OR", "GR", "SV", "All"]
    if !(line_input in line_colors)
        error("LineCode must be one of: RD, BL, YL, OR, GR, SV, or All")
    else
        return line_input
    end
end

function get_station_names_and_codes()
    r = wmata_request(wmata.station_list_url)

    station_codes = []
    station_names = []

    for station in r["Stations"]
        push!(station_codes, station["Code"])
        push!(station_names, station["Name"])
    end

    stations = Dict(zip(station_names, station_codes))

    return stations
end

# verify that a station code has a match in the WMATA endpoint.
function verify_station_input(station_input)
    stations = get_station_names_and_codes()

    if !(station_input in values(stations))
        error("$station_input is not a valid station code.\nTry using station_list to find and verify your station code.")
    else
        return station_input
    end
end

#=
support optional argument in functions that involve pulling details
    based on a station code - enables a user to use a station name if they
    don't know the station code.
=#
function get_station_code(StationName::String)
    stations = get_station_names_and_codes()

    if !(StationName in keys(stations))
        error("$StationName is not a valid station name.")
    else
        return stations[StationName]
    end
end
