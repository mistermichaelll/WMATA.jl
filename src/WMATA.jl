module WMATA
include("authentication.jl")
include("rail.jl")

import DataFrames.DataFrame, JSON.parse, HTTP.request, DataFrames.rename!, DataFrames.names, DataFrames.nrow
export WMATA_auth
export get_rail_predictions, get_station_list, get_station_timings, get_path_between, get_station_to_station
export get_rail_incidents, get_train_positions

end