include("api.jl")

function WMATA_auth(SubscriptionKey::String)
    url = "https://api.wmata.com/Misc/Validate"
    subscription_key = Dict("api_key" => SubscriptionKey)

    try 
        r = request("GET", url, subscription_key)
    catch 
        @error "Invalid Subscription Key. Please refer to your WMATA account."
    end

    global wmata = wmata_API(
        SubscriptionKey, 
        "https://api.wmata.com/Rail.svc/json/jStations", 
        "https://api.wmata.com/Rail.svc/json/jStationTimes", 
        "https://api.wmata.com/StationPrediction.svc/json/GetPrediction/", 
        "https://api.wmata.com/Rail.svc/json/jPath?", 
        "https://api.wmata.com/Rail.svc/json/jSrcStationToDstStationInfo"
    )

    println("Authentication complete.")
end
