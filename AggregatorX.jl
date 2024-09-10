module AggregatorX

import JSON

using JuMP

export buildaggregator
export optimizeaggregator
# export all concrete types
export FFRGroup # Groups
export IndexedTimeStruct # TimeStructs
export SimpleCharger, SimpleBattery,MegaCharger # Resources
export SimpleGrid # Grids, obsolete
export SimpleMarket # Markets
export MinAverageLoad # Loads 
export Interconnection, GridToResource, ResourceToLoad, ResourceToAggregator # Connections

include("AggregatorXUtilities.jl")
include("AggregatorXComponents.jl")
include("AggregatorXMethods.jl")

include("BuildAggregator.jl")
include("OptimizeAggregator.jl")
end