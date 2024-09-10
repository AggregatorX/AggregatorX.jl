module AggregatorX

import JSON

using JuMP

export  buildaggregator
export optimizeaggregator
export FFRGroup
export build_typetable # temporary

include("AggregatorXUtilities.jl")


include("AggregatorXComponents.jl")
# Module for constructing AggregatorX objects from system description as JSON file
include("BuildAggregator.jl")
#using .BuildAggregator # usage: aggregator = buildaggregator("systemdescription.json")

include("AggregatorXMethods.jl")
include("OptimizeAggregator.jl")
#using .OptimizeAggregator

# optimizeaggregator(aggregator)

end