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

# verify that a station code has a match in the WMATA endpoint.
function verify_station_input(station_input)
    # this function relies on the same endpoint that the station_list function does.
    r = wmata_request(wmata.station_list_url)

    valid_station_codes = push!([station["Code"] for station in r["Stations"]], "All")

    if !(station_input in valid_station_codes)
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
    r = wmata_request(wmata.station_list_url)

    stations = Dict(
        [station["Name"] for station in r["Stations"]] .=> [station["Code"] for station in r["Stations"]]
    )

    if !(StationName in keys(stations))
        error("$StationName is not a valid station name.")
    else
        return stations[StationName]
    end
end

#=
it makes sense that we'd want to parse arrival times to a better format (aka one that we can do arithmetic on),
  there is probably a more Juli-onic way to do this but this is my best attempt at the moment.
=#
function convert_arrival_times(arrival_times::Vector{String})
    converted_times = []
    for time in arrival_times
        if time == "ARR" || time == "BRD"
            push!(converted_times, 0)
        elseif time == "---"
            push!(converted_times, missing)
        else
            push!(converted_times, Base.parse(Int64, time))
        end
    end
    return convert(Vector{Union{Missing, Int64}}, converted_times)
end
