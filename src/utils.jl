#=
since we're dealing with user input, it makes sense to build in some checks to the functions 
so that mistakes are obvious and not mysterious.
=#

# verify that a linecode is one that makes sense
function verify_line_input(line_input)
    line_colors = ["RD", "BL", "YL", "OR", "GR", "SV", "All"]
    if !(line_input in line_colors)
        error("ERROR: line must be one of: RD, BL, YL, OR, GR, SV, or All")
    else 
        return(line_input)
    end
end

# 
function verify_station_input(station_input)
    # this function relies on the same endpoint that the station_list function does.
    subscription_key = Dict("api_key" => WMATA_AuthToken)
    r = request("GET", "https://api.wmata.com/Rail.svc/json/jStations", subscription_key)
    r = parse(String(r.body))
    
    valid_station_codes = push!([station["Code"] for station in r["Stations"]], "All")

    if !(station_input in valid_station_codes)
        error("ERROR: $station_input is not a valid station code.\nTry using station_list to find and verify your station code,\nor use \"All\"")
    else 
        return(station_input)
    end
end

