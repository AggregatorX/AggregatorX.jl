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

function build_timestruct(timestruct::Dict{String,Any}, timestructtype::Any)

end

"""
Returns an array of connection objects

The deprecated version is to have an interconnection inside a connection dict element

Prefered just vector inside connection key
"""
function build_connection(connectiondef::Any, typetable, ids)
    if isa(connectiondef, Dict)
        connections = Dict{String, Any}()
        for (ct, carray) in connectiondef # For each connection type in connectiondef
            if ct != "Interconnection" # only this allowed
                print(" \n Warning: type " * ct * " is not supported \n")
                continue
            end
            connection_type = typetable[ct] # Convert string to type
            connection_array = Vector{connection_type}(undef,length(carray)) # Initalize Vector of particular type to hold connection objects        
            
            for (i,idpair) in enumerate(carray) # loop over id-pairs in connection array
                if !issubset(Set(idpair), ids) # Check if id in id-pair exists
                    println("Error: Missing id. Id in " * string(Set(idpair)) * " not found in " * string(ids))
                    throw(MissingIdException())
                end

                connection = build_aggregatorx_object(connection_type, idpair) # Create single aggregatorx connection object
                
                connection_array[i] = connection # Add to array of connectiontype
            end
            
            connections[ct] = connection_array # Add to dict of connectiontypes
        end
        return connections["Interconnection"]
    end

    # Implement new version with a direct vector
    if isa(connectiondef, Array)

        connection_array = Vector{Connection}(undef,length(connectiondef)) # Initalize Vector of particular type to hold connection objects  
        
        for (i,idpair) in enumerate(connectiondef) # loop over id-pairs in connection array
            if !issubset(Set(idpair), ids) # Check if id in id-pair exists
                println("Error: Missing id. Id in " * string(Set(idpair)) * " not found in " * string(ids))
                throw(MissingIdException())
            end

            connection = build_aggregatorx_object(typetable["Connection"],idpair) # Create single aggregatorx connection object
            
            connection_array[i] = connection # Add to array of connectiontype
        end

        return connection_array
    end

    
end