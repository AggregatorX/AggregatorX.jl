# Type declarations (must come before constructor functions)

abstract type AggregatorXAny end

abstract type Component <: AggregatorXAny end

abstract type Group <: AggregatorXAny end

abstract type Grid <: Component end

abstract type Market <: Component end

abstract type Resource <: Component end

abstract type Node <: Component end

# - Node -
mutable struct StandardNode <: Node
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    id::Signed
end

# - SimpleCharger -
mutable struct SimpleCharger <: Resource 
    power::Dict{Integer, Vector{VariableRef}}
    up_capacity::Vector{VariableRef}
    down_capacity::Vector{VariableRef}
    up_activation::Dict{Integer, Vector{VariableRef}}
    down_activation::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    max_power::Real
    id::Signed
end

# - SimpleBattery -
mutable struct SimpleBattery <: Resource
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    state_of_charge::Vector{VariableRef}
    up_capacity::Vector{VariableRef}
    down_capacity::Vector{VariableRef}
    up_activation::Dict{Integer, Vector{VariableRef}}
    down_activation::Dict{Integer, Vector{VariableRef}}
    capacity::AbstractFloat
    initial_charge::AbstractFloat
    max_charge::AbstractFloat
    max_discharge::AbstractFloat
    class::String
    id::Integer
end

## Groups
mutable struct FFRGroup <: Group
    up_capacity::Vector{VariableRef}
    resources::Set{Int} # Set of tuples of resource and group ids.
    markets::Set{Int} # Set of tuples of group and market ids.  
    class::String  
    id::Integer
end

mutable struct FCRGroup <: Group
    up_capacity::Vector{AffExpr} # These could be AffExpr to reduce number of variables.
    down_capacity::Vector{AffExpr}
    up_activation::Vector{VariableRef}
    down_activation::Vector{VariableRef}
    resources::Set{Int} # Set of tuples of resource and group ids.
    markets::Set{Int} # Set of tuples of group and market ids.  
    class::String  
    id::Integer
end

## - Time structure -
abstract type TimeStruct <: AggregatorXAny end
# Define some minimum requirements for all concrete types? I.e. there must be a periods variable
# Timestructur that has no absolute duration or relation to absolute time, it is simply an index.
struct IndexedTimeStruct <: TimeStruct 
    periods::Int # The number of time periods
end

#  - Grids -

struct SimpleGrid <: Grid
    price::Array{AbstractFloat}
    id::Integer
end

# - Markets -
struct SimpleMarket <: Market
    power::Dict{Integer, Vector{VariableRef}} # redundant?
    price:: Array{AbstractFloat}
    resource::Integer       
    sign::Integer
    class::String
    id::Integer
end

mutable struct SimpleDAMarket <: Market
    power::Dict{Integer, Vector{VariableRef}}
    price::Vector{AbstractFloat}
    resource::Integer       
    sign::Integer
    class::String
    id::Integer
end

mutable struct FFRProfil <: Market
    up_capacity::Vector{VariableRef} # reserved capacity
    price::Vector{AbstractFloat}
    armed::Vector{Bool} # Periods where FFR is armed
    sign::Integer
    class::String
    id::Integer
end

# "FCR-N"
mutable struct FCRN <: Market
    up_capacity::Vector{VariableRef}
    down_capacity::Vector{VariableRef}
    up_activation::Vector{VariableRef}    
    down_activation::Vector{VariableRef}
    price_capacity::Vector{AbstractFloat}
    price_up_activation::Vector{AbstractFloat}
    price_down_activation::Vector{AbstractFloat}
    df::Vector{AbstractFloat} # Frequency deviation in Hz
    dfmax::AbstractFloat # maximum frequency deviation
    sign::Integer
    class::String
    id::Integer
end

# - Loads -
abstract type Load <: Resource end

abstract type ChargingStation <: Load end

struct MinLoad <: Load    
    pmin::Number
    source::Integer
    id::Integer
end

"A load where the average load over the simulation time must be greatet than some minimum load."
struct MinAverageLoad <: Load
    pmin::Number # minimum average power
    id::Integer
end

# for testing
struct MegaCharger <: ChargingStation
    pmax::Number
    id::Integer
end

# - Connections -
abstract type AbstractConnection <: Component end # Should connections rather be subtype of AggregatorXAny?

# Perhaps rename fields that reference ids as sourceId, sinkId etc.?
struct Connection <: AbstractConnection
    source::Integer
    sink::Integer
end

# ---Constructor wrapper methods ---
# for instantiating aggragtorX objects. One constructor needed for each type aggregatorx type
## - Groups

include("AggregatorXConstructors.jl")
