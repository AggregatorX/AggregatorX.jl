# Resources

function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any}, 
    connections::Vector{Interconnection})

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

    return SimpleCharger(power, up_capacity, down_capacity, sources, r["max_power"], id)
end

function build_aggregatorx_object(::Type{SimpleBattery}, b::Dict{String, Any}, 
    connections::Vector{Interconnection})

    id = b["id"]

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

    return SimpleBattery(power, sources, state_of_charge, up_capacity, 
    down_capacity, b["capacity"], b["initial_charge"], b["max_charge"], b["max_discharge"],
     b["class"], b["id"])
end

# Markets
function build_aggregatorx_object(mt::Type{SimpleMarket}, m::Dict{String, Any}, 
    connections::Vector{Interconnection})

    id = m["id"]
    resource = -1
    for c in connections
        if c.sink == id
            resource = c.source
        end
    end

    power = Dict(resource => Vector{VariableRef}())

    return SimpleMarket(power, m["price"], resource, m["sign"], m["class"], m["id"])
end

function build_aggregatorx_object(t::Type{SimpleDAMarket}, m::Dict{String, Any}, 
    connections::Vector{Interconnection})

    id = m["id"]
    resource = -1
    for c in connections
        if c.source == id
            resource = c.sink
        end
    end
    power = Dict(resource => Vector{VariableRef}())
    
    return SimpleDAMarket(power, m["price"], resource, m["sign"], m["class"],  id)
end

# Groups

function build_aggregatorx_object(gt::Type{FFRGroup}, g::Dict{String, Any})
    up_capacity = Vector{VariableRef}()

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
    return FFRGroup(up_capacity, resources, markets, g["class"], g["id"])
end