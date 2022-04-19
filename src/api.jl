# struct containing api key and urls
struct wmata_API 
    api_key::String 
    station_list_url::String
    station_timings_url::String 
    rail_predictions_url::String
    paths_url::String 
    station_to_station_url::String
    train_positions_url::String
end