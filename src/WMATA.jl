module WMATA
include("authentication.jl")
include("rail.jl")

import HTTP.request
using DataFrames
using JSON3
export WMATA_auth
export get_rail_predictions, get_station_list, get_path_between, get_station_to_station
export get_rail_incidents, get_train_positions
export wmata_request

end
