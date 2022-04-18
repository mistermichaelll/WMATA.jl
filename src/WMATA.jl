module WMATA
include("authentication.jl")
include("rail.jl")

import DataFrames.DataFrame, JSON.parse, HTTP.request, DataFrames.rename!, DataFrames.names
export rail_predictions, station_list, station_timings, WMATA_auth, path_between, station_to_station, get_train_positions, test_station_list

end