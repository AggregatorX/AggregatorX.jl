module BuildAggregator

export buildaggregator,  bob

include("AggregatorXUtilities.jl")

# Instantiates aggregatorx objects from json descrption
function buildaggregator()
    # Requires tables that translates string description of type (from json) to a Type object
    typetable = build_typetable()

    # Iterates ove all component types
    components = ("Timestruct", "Grids", "Loads", "Markets", "Resources", "Connections") # Maybe keep timestruct seperate

    aggregator = Dict{String, Any} # ? Could we make a type system where we can be more specific than Any
    for c in components
        # Functions that takes aggregatorx types and returns aggregatorx objects
        aggregator[c] = build_aggregatorx_object()
    end
    # returns aggregatorx objects
end

# Function to instantiate aggregatorx objects
include("AggregatorXComponents.jl")
# include AggregatorXComponentsCustom user defined components



# For testing
function bob()
    return " the builder!"
end

end