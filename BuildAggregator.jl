import JSON

"""
Instantiates aggregatorx objects from json descrption
"""
function buildaggregator(systemdescription::String)

    io = open(systemdescription, "r")
    sys = JSON.parse(io)

    validate_system_description(sys)

    typetable = build_typetable() # Translates string description of type (from json) to a AggregatorX Type

    ids = all_ids(sys) # List of all ids

    parts = ("TimeStruct", "Connection",  "Market", "Resource", "Group", "Node" ) 
    
    aggregator = Dict{String, Any}() # One entry for each parttype

    # Iterates over all part types
    for p in parts
        if p == "TimeStruct"

            aggregator[p] = build_aggregatorx_object(typetable[sys[p]["type"]], sys[p])

        elseif p == "Connection"
            
            aggregator[p] = build_connection(sys[p], typetable, ids)

        elseif p == "Group"

            if haskey(sys,"Group") # Groups are optional entities
                
                groups = Set{typetable[p]}() # Initalize set to hold group objects

                for g in sys[p]
                    grouptype = typetable[g["class"]]
                    group = build_aggregatorx_object(grouptype, g)
                    push!(groups, group)
                end 

                aggregator[p] = groups
            end

        elseif p == "Market" || p == "Resource" || p == "Node"

            partdef = sys[p] # Vector of Dicts for each component (except for timestruct)

            component_array = Vector{typetable[p]}(undef, length(partdef)) # Vector to hold each component of a particular type
            
            for (i,c)  in enumerate(partdef) # each component of component type
                componenttype = typetable[c["type"]]
                if applicable(build_aggregatorx_object, componenttype, c, aggregator["Connection"] )
                    component_array[i] = build_aggregatorx_object(componenttype, c, aggregator["Connection"])
                else
                    component_array[i] = build_aggregatorx_object(componenttype, c) # Temporary, implement all on above form
                    println("buidling with old version")
                end
            end

            aggregator[p] = component_array
        
        else
            print("Warning: Read undefined system description key. Please check JSON system description")
        end
    end
    
    #TEMP
    return (sys,aggregator)
    #TEMP
end