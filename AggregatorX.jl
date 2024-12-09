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
export LinearTariff # Grids
export SimpleMarket, SimpleDAMarket, FFRProfil, FCRN # Markets
export MinAverageLoad, MinLoad, FixedLoad, VariableLoad # Loads 
export Connection # Connections
export IncompleteSystemException, DuplicateIdException, MissingIdException

# Internal functions. Export for testing
export parse_data, build_connection, build_typetable, all_ids, get_component, build_aggregatorx_object
export set_optimization_variables, set_optimization_constraints, set_objective, get_objective_term

include("AggregatorXUtilities.jl")
include("AggregatorXComponents.jl")
include("AggregatorXMethods.jl")
include("AggregatorXExceptions.jl")

include("BuildAggregator.jl")
include("OptimizeAggregator.jl")

end