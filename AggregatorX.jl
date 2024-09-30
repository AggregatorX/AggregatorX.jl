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
export SimpleMarket, SimpleDAMarket, FFRProfil, FCR_N_D1 # Markets
export MinAverageLoad # Loads 
export Interconnection, Connection # Connections
export IncompleteSystemException, DuplicateIdException, MissingIdException

# Internal functions. Export for testing
export parse_data, build_connection, build_typetable, all_ids

include("AggregatorXUtilities.jl")
include("AggregatorXComponents.jl")
include("AggregatorXMethods.jl")
include("AggregatorXExceptions.jl")

include("BuildAggregator.jl")
include("OptimizeAggregator.jl")
end