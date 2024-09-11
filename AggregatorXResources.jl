# - SimpleCharger -
struct SimpleCharger <: Resource 
    max_power::Real
    p::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    id::Signed
end

function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any})
    return SimpleCharger(r["max_power"],r["id"])
end

function SimpleCharger(max_power, id) # Temporary alternative constructor
    vr = Vector{VariableRef}()
    p = Dict(0 => vr)
    sources = [0]
    return SimpleCharger(max_power, p, sources, id)
end

# - SimpleBattery -
mutable struct SimpleBattery <: Resource
    capacity::Real    
    id::Signed
    charge::Any
end

function build_aggregatorx_object(rt::Type{SimpleBattery}, r::Dict{String, Any})
    return SimpleBattery(r["capacity"],r["id"], missing)
end



