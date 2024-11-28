module AggregatorX

import JSON

using JuMP

# export user functions
export buildaggregator
export optimizeaggregator

# export all concrete types
export FFRGroup # Groups
export IndexedTimeStruct # TimeStructs
export StandardNode
export SimpleCharger, SimpleBattery,MegaCharger # Resources
export SimpleGrid # Grids, obsolete
export SimpleMarket, SimpleDAMarket, FFRProfil, FCRN # Markets
export MinAverageLoad, MinLoad, FixedLoad # Loads 
export Connection # Connections
export IncompleteSystemException, DuplicateIdException, MissingIdException

# Internal functions. Export for testing
export parse_data, build_connection, build_typetable, all_ids, get_component, build_aggregatorx_object

include("AggregatorXUtilities.jl")
include("AggregatorXComponents.jl")
include("AggregatorXMethods.jl")
include("AggregatorXExceptions.jl")

include("BuildAggregator.jl")
include("OptimizeAggregator.jl")

end