module AggregatorX

import JSON

export  buildaggregator
# export buildaggregator, optimizeaggregator

# Construct AggregatorX objects from system description
include("BuildAggregator.jl")

using .BuildAggregator

# function buildaggregator(file::String) end
# usage: aggregator = buildaggregator(systemdescription)

include("OptimizeAggregator.jl")
# using .OptimizeAggregator

# optimizeaggregator(aggregator)

end