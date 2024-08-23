module AggregatorX

import JSON

using JuMP

export  buildaggregator
export optimizeaggregator
export build_typetable # temporary

include("AggregatorXUtilities.jl")
include("AggregatorXComponents.jl")
include("AggregatorXMethods.jl")

# Module for constructing AggregatorX objects from system description as JSON file
include("BuildAggregator.jl")
#using .BuildAggregator # usage: aggregator = buildaggregator("systemdescription.json")

include("OptimizeAggregator.jl")
#using .OptimizeAggregator

# optimizeaggregator(aggregator)

end