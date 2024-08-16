# Utility functions for AggregatorX
using InteractiveUtils

# Dictionary that translates type string name from json description to Julia Type

function build_typetable()
    t = allsubtypes(AggregatorXAny)
    s = string.(t)
    for (i,str) in enumerate(s)
        pos = findlast('.', str)
        s[i] = str[pos+1:end]
    end
    z = zip(s,t)
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