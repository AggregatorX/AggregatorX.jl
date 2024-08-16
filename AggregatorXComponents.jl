# Define different methods depending on type
# Need to add new for every new type of resources (should maybe have *one* place where used extends resources)

# --- Type definitions ---

# -Time structures -
abstract type AggregatorXAny end

abstract type Component <: AggregatorXAny end

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

struct SimpleBattery <: Resource
    capacity::Real
    id::Signed
end

#  - Grids -
abstract type Grid <: Component end

struct SimpleGrid <: Grid
    price::Array{AbstractFloat}
end

# - Markets -
abstract type Market <: Component end

struct SimpleMarket <: Market
    price:: Array{AbstractFloat}
end

# - Loads -
abstract type Load <: Component end

abstract type ChargingStation <: Load end

"A load where the average load over the simulation time must be greatet than some minimum load."
struct MinAverageLoad <: Load
    pmin::Number # minimum average power
end

# for testing
struct MegaCharger <: ChargingStation
    pmax::Number
end

# - Connections -
abstract type Connection <: Component end # Should connections rather be subtype of AggregatorXAny?

# Perhaps rename fields that reference ids as sourceId, sinkId etc.?
struct Interconnection <: Connection
    source::Integer
    sink::Integer
    name::String
end

struct GridToResource <: Connection
    grid::Integer
    resource::Integer
end

struct ResourceToLoad <: Connection
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
    return SimpleBattery(r["capacity"],r["id"])
end

## - Grids -
function build_aggregatorx_object(gt::Type{SimpleGrid}, g::Dict{String, Any})
    return SimpleGrid(g["price"])
end

## - Loads -
function build_aggregatorx_object(lt::Type{MinAverageLoad}, l::Dict{String, Any})
    return MinAverageLoad(l["pmin"])
end

## - Markets -
function build_aggregatorx_object(mt::Type{SimpleMarket}, m::Dict{String, Any})
    return SimpleMarket(m["price"])
end

# --- Optimization propblem definition functions ---

## - Set up variables -

## - Set up constraints - 