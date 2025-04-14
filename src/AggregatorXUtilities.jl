# Utility functions for AggregatorX
using InteractiveUtils
using DelimitedFiles

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
    #component = union(aggregator["Resource"], aggregator["Market"])
    for (k,v) in aggregator
        if k == "TimeStruct" || k == "Connection" || k == "DATADIR" || k == "SYSDIR" # Seems complicated. Better to check if has id field
            continue
        end
        for c in v
            if c.id == id
                return c
            end
        end
    end
    println("Warning: Could not find object with id " * string(id))
end

function all_ids(sys::Dict{String, Any})
    component_with_id = ["Resource", "Market", "Group", "Node", "Grid"]

    ids = Set{Integer}()

    for c in component_with_id
        if haskey(sys, c)
            v = sys[c]
            for i in v
                push!(ids, i["id"])
            end
        end
    end

    return ids
end

"""
    parse_data(data::Vector{AbstractFloat})

return Vector{Real}

The parse_data() function is used to handle various input formats for component parameters
that expect an array of numbers (it is not used for parameters ).

The following behaviors are handled:

A single number     -> is expanded to a array of appropriate length with constant values.
An array of numbers -> is returned as is.
An absolute path    -> return data at this location as a vector 
A string            -> assume filename, combine with datadir to get data at this location

The canononical way to use it is the parse_data(data::Any, aggregator::Dict{String, Any}) method.

The parse data function dispatches on various data types and returns a vector
which represent some parameter data for the system. This is the trivial function
if the vector is already defined in the JSON file.
"""

function parse_data(data::Any, aggregator::Dict{String, Any})
    if isa(data, String)
        if isabspath(data) # data is located at absolute path
            return parse_data(data)
        else # data is located in a file in the DATADIR
            filepath = joinpath(aggregator["DATADIR"], data)
            return parse_data(filepath)
        end
    else # Numeric data
        if length(data) == 1
            return parse_data(data, aggregator["TimeStruct"].periods)
        else
            parse_data(data)
        end
    end
end

function parse_data(data::Real, N::Integer)
    return ones(N) .* data
end

function parse_data(data::Vector{<:Number})
    return data
end

function parse_data(data::Vector{Any})
    # JSON parse returns a Vector{Any} for a vector [..] in the data file

    # Check if the elements are strings or numbers
    element = data[1]
    if typeof(element) <: AbstractString || typeof(element) <: Number
        parse_data(element, data)
    else
        throw(TypeError)
    end
    return data
end

# for vector of numbers
function parse_data(element::Number, data::Vector{Any})
    return convert(Vector{Float64}, data)
end

# If multiple strings assume file and function
function parse_data(element::AbstractString, data::Vector{Any})
    return Nothing # Not yet implemented
end

"""
    parse_data(data::String)

The string data argument represents a file where the data is stored. The function
reads the data and returns an appropriate string based on the data.

The file must contain a single columen of numbers.

DelimitedFiles.readdlm is used to read the data.
"""
function parse_data(datafile::String)
    if isabspath(datafile)
        data = open(readdlm, datafile) # Apply readdlm (from DelimitedFiles) to filepath
    else # depreceated to get here directly, constructors should call parse_data(data, aggregator)
        filepath = joinpath(pwd(), datafile)
        print("Warning: Deprecated parsing function. Assuming data directory to be: " * pwd() * "\n") 
        if isfile(filepath)
            data = open(readdlm, filepath)
        else
            error("File " * filepath * ", not found")
        end
    end
    #filepath = joinpath(@__DIR__, datafile)
    #filepath = joinpath(DATADIR, datafile)
    
    if size(data)[2] != 1
        throw(DimensionMismatch("More than one column in file. Input data must be a single vector."))
    end

    return data[:,1]
end
#=
function parse_data(datafile::String, aggregator::Dict{String, Any})
    #datadir = aggregator["datadir"]
    #filepath = joinpath(datadir, datafile)

    data = open(readdlm, filepath) # Apply readdlm (from DelimitedFiles) to filepath
    
    if size(data)[2] != 1
        throw(DimensionMismatch("More than one column in file. Input data must be a single vector."))
    end

    return data[:,1]
end
=#
# ----

function get_class(c::Dict{String, Any})
    if haskey(c, "class")
        class = c["class"]
    else
        class = ""
    end
    return class
end

function validate_system_description(sys)

    required = ["TimeStruct", "Node", "Market", "Resource", "Connection"]
    syskeys = keys(sys)
    for k in required
        if !(k in syskeys)
            println("Mandatory key " * string(k) * " not found in system description")
            throw(IncompleteSystemException())
        end
    end

    # Validate each type 
    resources = sys["Resource"]
    for r in resources
        if !haskey(r, "type")
            println("A resource is missing type description")
            println(r)
            throw(IncompleteSystemException)
        end
        resource_type = TYPETABLE[r["type"]]
        if resource_type == ThermalLoad   
            validate_component(resource_type, r ,  sys["TimeStruct"])
        end
    end
end

function validate_component(t::typeof(ThermalLoad), r::Dict, ts::Dict)
    k = keys(r)
    required_keys = [
        "load", "inital_temperature", "min_temperature", "max_temperature",
        "ambient_temperature", "heat_capacity", "heat_loss_factor", "max_power"
        ]
    for rk in required_keys
        if !(rk ∈ k)
            println("Mandatory key " * rk * "missing from ThermalLoad definition")
            throw(IncompleteSystemException())
        end
    end
end

function all_components(aggregator)
    if haskey(aggregator, "Grid")
        union(aggregator["Resource"], aggregator["Market"], aggregator["Node"], aggregator["Grid"])
    else
        union(aggregator["Resource"], aggregator["Market"], aggregator["Node"])
    end
end

function getsource(id, connections)
    source = 0
    for c in connections
        if c.sink == id
            source =  c.source
        end
    end
    return source
end