module BuildAggregator

export buildaggregator
export optimizeaggregator
export build_typetable # temporary

import JSON

include("AggregatorXUtilities.jl")

# Instantiates aggregatorx objects from json descrption
function buildaggregator(systemdescription::String)

    io = open(systemdescription, "r");
    sys = JSON.parse(io)

    # Requires tables that translates string description of type (from json) to a Type object
    typetable = build_typetable()

    # Iterates ove all component types
    parts = ("TimeStruct", "Grid", "Load", "Market", "Resource") # Maybe keep timestruct seperate
    # Removed , "Connection" temporarily

    aggregator = Dict{String, Any}() # One entry for each parttype
    for p in parts
        if p == "TimeStruct"
            partdef = sys[p]
            println(typetable)
            componenttype = typetable[partdef["type"]]
            aggregator[p] = build_aggregatorx_object(componenttype, partdef)
        else
            partdef = sys[p] # Vector of Dicts for each component (except for timestruct)
            component_array = Vector{typetable[p]}(undef, length(partdef)) # Vector to hold each component of a particular type
            for (i,c)  in enumerate(partdef) # each component of component type
                println(c)
                componenttype = typetable[c["type"]]
                component_array[i] = build_aggregatorx_object(componenttype, c)
            end
            aggregator[p] = component_array
        end
    end
    # returns aggregatorx objects
    #TEMP
    return (sys,aggregator, typetable)
    #TEMP
end

# Function to instantiate aggregatorx objects
include("AggregatorXComponents.jl")
# include AggregatorXComponentsCustom user defined components

end