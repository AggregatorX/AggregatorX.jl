module AggregatorX

import JSON

export  buildaggregator, you4, bob 
# export buildaggregator, optimizeaggregator

# Construct AggregatorX objects from system description
include("BuildAggregator.jl")

using .BuildAggregator

# function buildaggregator(file::String) end
# usage: aggregator = buildaggregator(systemdescription)

include("OptimizeAggregator.jl")
# using .OptimizeAggregator

# optimizeaggregator(aggregator)

# For testing
function you4()
    print(bob())
    return "rock"
end

end