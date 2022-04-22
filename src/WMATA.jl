module WMATA
include("authentication.jl")
include("rail.jl")

import DataFrames.DataFrame, JSON.parse, HTTP.request, DataFrames.rename!, DataFrames.names, DataFrames.nrow
export get_rail_predictions, get_station_list, get_station_timings, WMATA_auth, get_path_between, get_station_to_station, get_train_positions
export get_rail_incidents

end