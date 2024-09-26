# Type declarations (must come before constructor functions)

abstract type AggregatorXAny end

abstract type Component <: AggregatorXAny end

abstract type Group <: AggregatorXAny end

abstract type Grid <: Component end

abstract type Market <: Component end

abstract type Resource <: Component end

# - SimpleCharger -
mutable struct SimpleCharger <: Resource 
    power::Dict{Integer, Vector{VariableRef}}
    up_capacity::Vector{VariableRef}
    down_capacity::Vector{VariableRef}
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
    capacity::Vector{VariableRef}
    activation::Vector{VariableRef}
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
mutable struct FCR_N_D1 <: Market
    capacity::Vector{VariableRef}
    activation::Vector{VariableRef}
    price_capacity::Vector{AbstractFloat}
    price_activation::Vector{AbstractFloat}
    df::Vector{AbstractFloat} # Frequency deviation in Hz
    sign::Integer
    class::String
    id::Integer
end

# - Loads -
abstract type Load <: Component end

abstract type ChargingStation <: Load end

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
abstract type Connection <: Component end # Should connections rather be subtype of AggregatorXAny?

# Perhaps rename fields that reference ids as sourceId, sinkId etc.?
struct Interconnection <: Connection
    source::Integer
    sink::Integer
end

struct GridToResource <: Connection
    grid::Integer
    resource::Integer
end

struct ResourceToLoad <: Connection
    resource::Integer
    load::Integer
end

struct ResourceToAggregator <: Connection
    resource::Integer
    aggregator_set::Integer
end


# ---Constructor wrapper methods ---
# for instantiating aggragtorX objects. One constructor needed for each type aggregatorx type
## - Groups

include("AggregatorXConstructors.jl")

## - Loads -
function build_aggregatorx_object(lt::Type{MinAverageLoad}, l::Dict{String, Any})
    return MinAverageLoad(l["pmin"],l["id"])
end





function build_aggregatorx_object(ct::Type{GridToResource}, idpair::Array{Any})
    return GridToResource(idpair[1], idpair[2])
end

function build_aggregatorx_object(ct::Type{ResourceToLoad}, idpair::Array{Any})
    return ResourceToLoad(idpair[1], idpair[2])
end

function build_aggregatorx_object(ct::Type{ResourceToAggregator}, idpair::Array{Any})
    return ResourceToAggregator(idpair[1], idpair[2])
end

function build_aggregatorx_object(ct::Type{ResourceToAggregator}, id::Any)
    return ResourceToAggregator(id)
end
