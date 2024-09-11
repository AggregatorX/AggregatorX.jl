abstract type AggregatorXAny end

abstract type Component <: AggregatorXAny end

abstract type Group <: AggregatorXAny end

abstract type Grid <: Component end

abstract type Market <: Component end

abstract type Resource <: Component end

include("AggregatorXResources.jl")

## Groups
struct FFRGroup <: Group
    tech_class::String
    resources::Set{Tuple{Int,Int}} # Set of tuples of resource and group ids.
    markets::Set{Tuple{Int,Int}} # Set of tuples of group and market ids.    
    id::Integer
end

function build_aggregatorx_object(gt::Type{FFRGroup}, g::Dict{String, Any})
    tech_class = g["tech_class"]
    
    id = g["id"]

    markets = Set{Tuple{Int,Int}}()    
    mlist = g["markets"]
    for m in mlist
        push!(markets, (id,m))
    end

    resources = Set{Tuple{Int,Int}}()
    rlist = g["resources"]
    for r in rlist
        push!(resources, (r,id))
    end

    # Set all parameters, including tech_class and id
    return FFRGroup(tech_class, resources, markets, id)
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
    price:: Array{AbstractFloat}
    id::Integer
end

mutable struct SimpleDAMarket <: Market
    power::Vector{VariableRef}
    price::Vector{AbstractFloat}        
    sign::Integer
    class::String
    id::Integer
end

function build_aggregatorx_object(t::Type{SimpleDAMarket}, g::Dict{String, Any})
    power = Vector{VariableRef}()
    return SimpleDAMarket(power, g["price"], g["sign"], g["class"],  g["id"])
end

mutable struct FFRProfil <: Market
    capacity::Vector{VariableRef} # reserved capacity
    price::Vector{AbstractFloat}
    armed::Vector{Bool} # Periods where FFR is armed
    sign::Integer
    class::String
    id::Integer
end

function build_aggregatorx_object(t::Type{FFRProfil}, m::Dict{String, Any})
    N = length(m["armed"])
    price = ones(N) * m["price"]

    capacity = Vector{VariableRef}()

    return FFRProfil(capacity, price, m["armed"], m["sign"], m["class"],  m["id"])
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


## - TimeStructs
function build_aggregatorx_object(tst::Type{IndexedTimeStruct}, ts::Dict{String, Any})
    return IndexedTimeStruct(ts["periods"])
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
