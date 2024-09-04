# Define different methods depending on type
# Need to add new for every new type of resources (should maybe have *one* place where used extends resources)

# --- Type definitions ---

abstract type AggregatorXAny end

abstract type Component <: AggregatorXAny end

abstract type Grid <: Component end

abstract type Market <: Component end

struct Group <: AggregatorXAny
    tech_class::String
    markets::Set{Market}
    resources::Set{Tuple{Int,Int}}
    id::Integer
end

## - Time structure -
abstract type TimeStruct <: AggregatorXAny end
# Define some minimum requirements for all concrete types? I.e. there must be a periods variable
# Timestructur that has no absolute duration or relation to absolute time, it is simply an index.
struct IndexedTimeStruct <: TimeStruct 
    periods::Int # The number of time periods
end

## - Resources -
abstract type Resource <: Component end

struct SimpleCharger <: Resource 
    max_power::Real
    id::Signed
end

mutable struct SimpleBattery <: Resource
    capacity::Real    
    id::Signed
    chargeref::Any
end

#  - Grids -

struct SimpleGrid <: Grid
    price::Array{AbstractFloat}
    id::Integer
end

# - Markets -

struct SimpleMarket <: Market
    price:: Array{AbstractFloat}
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
## - TimeStructs
function build_aggregatorx_object(tst::Type{IndexedTimeStruct}, ts::Dict{String, Any})
    return IndexedTimeStruct(ts["periods"])
end

## - Resources -
function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any})
    return SimpleCharger(r["max_power"],r["id"])
end

function build_aggregatorx_object(rt::Type{SimpleBattery}, r::Dict{String, Any})
    return SimpleBattery(r["capacity"],r["id"], missing)
end

## - Grids -
function build_aggregatorx_object(gt::Type{SimpleGrid}, g::Dict{String, Any})
    return SimpleGrid(g["price"],g["id"])
end

## - Loads -
function build_aggregatorx_object(lt::Type{MinAverageLoad}, l::Dict{String, Any})
    return MinAverageLoad(l["pmin"],l["id"])
end

## - Markets -
function build_aggregatorx_object(mt::Type{SimpleMarket}, m::Dict{String, Any})
    return SimpleMarket(m["price"], m["id"])
end

## - Connections - 
function build_aggregatorx_object(ct::Type{Interconnection}, idpair::Array{Any})
    return Interconnection(idpair[1], idpair[2])
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
