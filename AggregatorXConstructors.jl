## - TimeStructs
function build_aggregatorx_object(tst::Type{IndexedTimeStruct}, ts::Dict{String, Any})
    return IndexedTimeStruct(ts["periods"])
end

## - Nodes
function build_aggregatorx_object(nt::Type{StandardNode}, n::Dict{String, Any}, connections::Vector{Connection})

    id = n["id"]

    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Int}(undef,0)
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}()
        elseif c.sink == id
            push!(sources, c.source)
        end
    end

    return StandardNode(power, sources, id)
end

## - Connections - 

function build_aggregatorx_object(ct::Type{Connection}, idpair::Array{Any})
    return Connection(idpair[1], idpair[2])
end

"""
Returns an array of connection objects
"""
function build_connection(connectiondef::Any, typetable, ids)

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

# Resources

# - Simple Charger -
function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any}, 
    connections::Vector{Connection})

    id = r["id"]

    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Int}(undef,0)
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}()
        elseif c.sink == id
            push!(sources, c.source)
        end
    end

    up_capacity = Vector{VariableRef}()
    down_capacity = Vector{VariableRef}()

    up_activation = Dict{Integer, Vector{AffExpr}}()
    down_activation = Dict{Integer, Vector{AffExpr}}()

    return SimpleCharger(power, up_capacity, down_capacity, up_activation, down_activation, sources, r["max_power"], id)
end

# - SimpleBattery -
function build_aggregatorx_object(::Type{SimpleBattery}, b::Dict{String, Any}, 
    connections::Vector{Connection})

    id = b["id"]
    class = get_class(b)

    # Find all connected components
    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Int}(undef,0)
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}()
        elseif c.sink == id
            push!(sources, c.source)
        end
    end

    state_of_charge = Vector{VariableRef}()

    up_capacity = Vector{VariableRef}()
    down_capacity = Vector{VariableRef}()

    up_activation = Dict{Integer, Vector{AffExpr}}()
    down_activation = Dict{Integer, Vector{AffExpr}}()

    return SimpleBattery(power, sources, state_of_charge, up_capacity, 
    down_capacity, up_activation, down_activation, b["capacity"], b["initial_charge"], b["max_charge"], b["max_discharge"],
     class, b["id"])
end

# - MinLoad - !Not tested!
function build_aggregatorx_object(lt::Type{MinLoad}, l::Dict{String, Any}, connections = Vector{Connection})

    pmin = l["pmin"]
    id = l["id"]
    
    source = -1
    for c in connections
        if c.sink == id
            source = c.source
        end
    end
    source == -1 ? "Warning: Source not found when building MinLoad (id=" * string(id) * ")" :

    return MinLoad(pmin, source, id)

end

# - MinAverageLoad - !Not tested!
function build_aggregatorx_object(lt::Type{MinAverageLoad}, l::Dict{String, Any})
    return MinAverageLoad(l["pmin"],l["id"])
end

# ------------
# - Markets -
# ------------

# SimpleMarket
function build_aggregatorx_object(mt::Type{SimpleMarket}, m::Dict{String, Any}, 
    connections::Vector{Connection})

    id = m["id"]
    sign = m["sign"]

    resource = -1
    if sign == -1
        for c in connections
            if c.sink == id
                resource = c.source
            end
        end
    elseif sign == 1
        for c in connections
            if c.source == id
                resource = c.sink
            end
        end
    end
    resource == -1 ? println("Error when builiding SimpleMarket. No connection found for market " * string(id) * " in connections") :

    power = Dict(resource => Vector{VariableRef}())

    price = parse_data(m["price"])

    class = get_class(m)

    return SimpleMarket(power, price, resource, sign, class , id)
end

# - SimpleDAMarket
function build_aggregatorx_object(t::Type{SimpleDAMarket}, m::Dict{String, Any}, 
    connections::Vector{Connection})

    id = m["id"]
    resource = -1
    for c in connections
        if c.source == id
            resource = c.sink
        end
    end

    power = Dict(resource => Vector{VariableRef}())

    class = get_class(m)
    
    return SimpleDAMarket(power, m["price"], resource, m["sign"], m["class"],  id)
end

# - FFRProfil -
function build_aggregatorx_object(t::Type{FFRProfil}, m::Dict{String, Any}, connections::Vector{Connection})
    N = length(m["armed"])
    price = ones(N) * m["price"]

    up_capacity = Vector{VariableRef}()

    return FFRProfil(up_capacity, price, m["armed"], m["sign"], m["class"],  m["id"])
end

# - FCR_N_D1 -
function build_aggregatorx_object(t::Type{FCR_N_D1}, m::Dict{String, Any}, connections::Vector{Connection})
    capacity = Vector{VariableRef}()
    activation = Vector{VariableRef}()
    return FCR_N_D1(capacity, activation, m["price_capacity"], m["price_activation"],
     m["df"], m["sign"], m["class"], m["id"])
end

# -----------
# - Groups -
#------------

function build_aggregatorx_object(gt::Type{FFRGroup}, g::Dict{String, Any})
    up_capacity = Vector{VariableRef}()

    markets = Set{Int}()    
    mlist = g["markets"] # vector of indicies of markets group is connected to. Defined in system file.
    for m in mlist
        push!(markets, m)
    end

    resources = Set{Int}()
    rlist = g["resources"] # vector of indicies of resources in group. Defined in system file.
    for r in rlist
        push!(resources, r)
    end

    # Set all parameters, including tech_class and id
    return FFRGroup(up_capacity, resources, markets, g["class"], g["id"])
end

function build_aggregatorx_object(gt::Type{FCRGroup}, g::Dict{String, Any})
    capacity = Vector{VariableRef}()
    activation = Vector{VariableRef}()

    markets = Set{Int}()    
    mlist = g["markets"]
    for m in mlist
        push!(markets, m)
    end

    resources = Set{Int}()
    rlist = g["resources"]
    for r in rlist
        push!(resources, r)
    end

    # Set all parameters, including tech_class and id
    return FCRGroup(capacity, activation, resources, markets, g["class"], g["id"])
end