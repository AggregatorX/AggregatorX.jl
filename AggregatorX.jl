module AggregatorX

import JSON

export  buildaggregator #optimizeaggregator
export build_typetable # temporary

# Module for constructing AggregatorX objects from system description as JSON file
include("BuildAggregator.jl")
using .BuildAggregator # usage: aggregator = buildaggregator("systemdescription.json")

include("OptimizeAggregator.jl")
# using .OptimizeAggregator

# optimizeaggregator(aggregator)

end