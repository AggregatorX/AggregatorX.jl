# Utility functions for AggregatorX
using InteractiveUtils

# Dictionary that translates type string name from json description to Julia Type

function build_typetable()
    t = allsubtypes(AggregatorXAny)
    s = string.(t)
    for (i,str) in enumerate(s) # strip module names from type description. Maybe only if not exported.
        pos = findlast('.', str)
        if pos !== nothing
            s[i] = str[pos+1:end]
        end
    end
    typetable = Dict(Pair(x...) for x in zip(s,t))
    return typetable
end

# "Return all levels of subtypes of a (parent) type."

function allsubtypes(parent)
    st = subtypes(parent)
    for t in st
        if !isempty(subtypes(t)) 
            st = [st; allsubtypes(t)]
        end
    end
    return st
end

function lstrip_last_dot(s::AbstractString)
    # Find the position of the last dot
    last_dot_position = findlast(isequal('.'), s)
    
    # Return the substring after the last dot
    return last_dot_position == nothing ? s : s[last_dot_position + 1:end]
end

function idx_to_id(aggregator, categories)
    id_map = Dict{String,Any}()    
    for category in categories
        components = aggregator[category]
        component_id_map = Vector{Int}(undef, length(components))
        for (i,component) in enumerate(components)
            component_id_map[i] = component.id
        end
        id_map[category] = component_id_map
    end
    return id_map
end

function init_expr_array(N)
    z = Vector{AffExpr}(undef, N)
    for i in eachindex(z)
        z[i] = 0.0
    end
    return z
end

function get_component(id ,aggregator)
    component = union(aggregator["Resource"], aggregator["Market"])
    for c in component
        if c.id == id
            return c
        end
    end
end
