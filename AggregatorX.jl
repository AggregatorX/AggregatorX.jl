module AggregatorX

import JSON
using JuMP

# export user functions
export buildaggregator
export optimizeaggregator

# export all concrete types
export FFRGroup, FCReGroup, FCRGroup # Groups
export IndexedTimeStruct # TimeStructs
export StandardNode
export SimpleCharger, SimpleBattery, MegaCharger, Generation # Resources
export LinearTariff # Grids
export SimpleMarket, SimpleDAMarket, FFRProfil, FCRN, FCRNe, FCRMarket, FCR_LERMarket, FCRD_Up_LER # Markets
export MinAverageLoad, MinLoad, FixedLoad, VariableLoad # Loads 
export Connection # Connections
export IncompleteSystemException, DuplicateIdException, MissingIdException

# export utilitites
export get_component, all_ids

# Internal functions. Export for testing, to be removed for release version
export parse_data, build_connection, build_typetable, build_aggregatorx_object
export set_optimization_variables, set_optimization_constraints, set_objective, get_objective_term

# Global variables

DATADIR = pwd() # directory where data files needed in the system description are stored
LARGE_NUMBER = 20 # for use in working with binary variables. Will depend on size of numbers in problem

export DATADIR

include("AggregatorXComponents.jl")
include("AggregatorXConstructors.jl")
include("AggregatorXMethods.jl")

include("AggregatorXUtilities.jl")
include("AggregatorXExceptions.jl")

include("BuildAggregator.jl")
include("OptimizeAggregator.jl")

end