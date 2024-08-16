# Utility functions for AggregatorX

# Dictionary that translates type string name from json description to Julia Type

function build_typetable()
    
    #return typetable
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