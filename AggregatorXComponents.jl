# Define different methods depending on type
# Need to add new for every new type of resources (should maybe have *one* place where used extends resources)

# --- Type definitions ---

# Time structures
abstract type AbstractTime end

# Define some minimum requirements for all concrete types? I.e. there must be a periods variable

# Timestructur that has no absolute duration or relation to absolute time, it is simply an index.
struct IndexedTimeStruct <: AbstractTime 
    periods::Int # The number of time periods
end


# ---Constructor wrapper methods ---
# for instantiating aggragtorX objects. One constructor needed for each type aggregatorx type
function build_aggregatorx_object(tst::Type{IndexedTimeStruct}, ts::Dict{String, Any})
    return IndexedTimeStruct(ts["periods"])
end


# Optimization propblem definition functions

## Set up variables

## Set up constraints