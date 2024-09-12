

function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any}, connections::Vector{Interconnection})
    power = Dict{Integer, Vector{VariableRef}}() 

    id = r["id"]

    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Int}(undef,0)
    for c in connections
        if c.source == id
            power[c.source] = Vector{VariableRef}()
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
    return SimpleBattery(r["capacity"],r["id"], missing)
end