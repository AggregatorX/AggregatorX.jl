import JSON

"""
Instantiates aggregatorx objects from json descrption
"""
function buildaggregator(systemdescription::String)

    io = open(systemdescription, "r");
    sys = JSON.parse(io)

    # Requires tables that translates string description of type (from json) to a Type object
    typetable = build_typetable()

    # Iterates over all component types
    parts = ("TimeStruct", "Connection", "Grid", "Market", "Resource", "Group" ) # Maybe keep timestruct seperate
   
    aggregator = Dict{String, Any}() # One entry for each parttype
    for p in parts
        if p == "TimeStruct"
            partdef = sys[p]
            componenttype = typetable[partdef["type"]]
            aggregator[p] = build_aggregatorx_object(componenttype, partdef)
        elseif p == "Connection"
            connections = Dict{String, Any}()
            partdef = sys[p]            
            # For each key (connectiontype) in partdef            
            for (ct, carray) in partdef
                connection_type = typetable[ct]
                connection_array = Vector{connection_type}(undef,length(carray))
                # for each id pair in Array
                for (i,idpair) in enumerate(carray)
                    # Create aggregatorx connection object
                    connection = build_aggregatorx_object(connection_type,idpair)
                    # Add to array of connectiontype
                    connection_array[i] = connection
                end
                # Add to dict of connectiontypes
                connections[ct] = connection_array
            end
            aggregator[p] = connections
        elseif p == "Group"
            partdef = sys[p] # returns a vector of group components
            groups = Set{typetable[p]}()
            for g in partdef
                grouptype = typetable[g["class"]]
                group = build_aggregatorx_object(grouptype, g)
                push!(groups, group)
            end 
            aggregator[p] = groups
        else
            partdef = sys[p] # Vector of Dicts for each component (except for timestruct)
            component_array = Vector{typetable[p]}(undef, length(partdef)) # Vector to hold each component of a particular type
            for (i,c)  in enumerate(partdef) # each component of component type
                componenttype = typetable[c["type"]]
                if c["type"] == "SimpleCharger" || c["type"] == "SimpleBattery"
                    component_array[i] = build_aggregatorx_object(componenttype, c, aggregator["Connection"]["Interconnection"])
                elseif c["type"] == "SimpleDAMarket" || c["type"] == "SimpleMarket"
                    component_array[i] = build_aggregatorx_object(componenttype, c, aggregator["Connection"]["Interconnection"])
                else
                    component_array[i] = build_aggregatorx_object(componenttype, c)
                end
            end
            aggregator[p] = component_array
        end
    end
    # returns aggregatorx objects
    #TEMP
    return (sys,aggregator)
    #TEMP
end
