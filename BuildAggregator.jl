import JSON

"""
Instantiates aggregatorx objects from json descrption
"""
function buildaggregator(systemdescription::String)

    io = open(systemdescription, "r")
    sys = JSON.parse(io)

    validate_system_description(sys)

    typetable = build_typetable() # Translates string description of type (from json) to a AggregatorX type

    ids = all_ids(sys) # List of all ids

    # The sequence we loop over the components is relevant. Some components may
    # need other components allready built during construction:
    # Several parts need TimeStruct
    # Markets, Resources, Nodes needs Connections
    # Markets may need Groups
    parts = ("TimeStruct", "Connection", "Group",  "Market", "Resource", "Node", "Grid" ) 
    
    aggregator = Dict{String, Any}() # One entry for each type of part
    
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

        elseif p == "Market" || p == "Resource" || p == "Node" || p == "Grid"

            if haskey(sys,p)
                component_array = Vector{typetable[p]}(undef, length(sys[p])) # Vector to hold each component
                for (i,c)  in enumerate(sys[p]) # each component of component type
                    componenttype = typetable[c["type"]]
                    if applicable(build_aggregatorx_object, componenttype, c, aggregator)
                        component_array[i] = build_aggregatorx_object(componenttype, c, aggregator)      
                    else
                        println("Matching constructor method not found.")
                    end
                end
            aggregator[p] = component_array
            end
        else
            print("Warning: Read undefined system description key. Please check JSON system description")
        end
    end
    
    #TEMP
    return (sys,aggregator)
    #TEMP
    
end