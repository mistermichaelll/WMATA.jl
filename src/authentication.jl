#= 
Function Name: WMATA_auth()
Purpose: WMATA's API has an endpoint which allows us to verify whether a subscription key is valid, or if there is 
an issue with their API. What I'd like to do here is make the other functions a bit less redundant by creating a function which 
creates a global variable titled WMATA_AuthToken. Instead of a user defining a "sub_key" and then calling that in every function in the package, 
they should be able to run this function, verify that the token is valid, and then not have to call it for each function.
=#
function WMATA_auth(SubscriptionKey::String)
    url = "https://api.wmata.com/Misc/Validate"
    subscription_key = Dict("api_key" => SubscriptionKey)
    try 
        r = request("GET", url, subscription_key)
    catch 
        @error "Invalid Subscription Key. Please refer to your WMATA account."
    end
    global WMATA_AuthToken = SubscriptionKey
end
