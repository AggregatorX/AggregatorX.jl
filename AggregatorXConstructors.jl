# Resources

function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any}, 
    connections::Vector{Interconnection})

    power = Dict{Integer, Vector{VariableRef}}() 

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

function SimpleCharger(max_power, id) # Temporary alternative constructor
    vr = Vector{VariableRef}()
    p = Dict(0 => vr)
    sources = [0]
    return SimpleCharger(max_power, p, sources, id)
end

function build_aggregatorx_object(rt::Type{SimpleBattery}, r::Dict{String, Any})    
    return SimpleBattery(r["capacity"], nothing, r["class"], r["id"])
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