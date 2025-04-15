# ----------------
# - TimeStructs -
# ----------------
function build_aggregatorx_object(tst::Type{IndexedTimeStruct}, ts::Dict{String, Any})
    return IndexedTimeStruct(ts["periods"])
end

# ----------------
# - Connections - 
#-----------------
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

# ----------
# - Nodes -
#-----------

# - StandardNode -
function build_aggregatorx_object(nt::Type{StandardNode}, n::Dict{String, Any}, aggregator::Dict{String,Any})

    connections = aggregator["Connection"]
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

# --------------
# - Resources -
#---------------

# - Simple Charger -
function build_aggregatorx_object(rt::Type{SimpleCharger}, r::Dict{String, Any}, aggregator::Dict{String,Any})
    connections = aggregator["Connection"]
    id = r["id"]
    N = aggregator["TimeStruct"].periods

    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Int}(undef,0)
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}()
        elseif c.sink == id
            push!(sources, c.source)
        end
    end

    up_capacity = Dict{Integer, Vector{VariableRef}}()
    down_capacity = Dict{Integer, Vector{VariableRef}}()
    
    up_activation = Dict{Integer, Vector{VariableRef}}()
    down_activation = Dict{Integer, Vector{VariableRef}}()

    if haskey(aggregator, "Group")
        groups = aggregator["Group"]        
        for g in groups
            if id in g.resources
                # For each group add an entry in det capacity and activation dicts    
                up_activation[g.id] = Vector{VariableRef}(undef, N)
                down_activation[g.id] = Vector{VariableRef}(undef, N)
                up_capacity[g.id] = Vector{VariableRef}(undef, N)
                down_capacity[g.id] = Vector{VariableRef}(undef, N)
            end
        end
    end

    return SimpleCharger(power, up_capacity, down_capacity, up_activation, down_activation, sources, r["max_power"], id)
end

# - SimpleBattery -
function build_aggregatorx_object(::Type{SimpleBattery}, b::Dict{String, Any}, aggregator::Dict{String,Any})

    connections = aggregator["Connection"]
    id = b["id"]
    N = aggregator["TimeStruct"].periods
    
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

    up_capacity = Dict{Integer, Vector{VariableRef}}()
    down_capacity = Dict{Integer, Vector{VariableRef}}()

    up_activation = Dict{Integer, Vector{VariableRef}}()
    down_activation = Dict{Integer, Vector{VariableRef}}()

    up_energy_reserve = Dict{Integer, Vector{VariableRef}}()
    down_energy_reserve = Dict{Integer, Vector{VariableRef}}()

    if haskey(aggregator, "Group")
        groups = aggregator["Group"]        
        for g in groups
            if id in g.resources
                # For each group add an entry in det capacity and activation dicts    
                up_activation[g.id] = Vector{VariableRef}(undef, N)
                down_activation[g.id] = Vector{VariableRef}(undef, N)
                up_capacity[g.id] = Vector{VariableRef}(undef, N)
                down_capacity[g.id] = Vector{VariableRef}(undef, N)
                up_energy_reserve[g.id] = Vector{VariableRef}(undef, N)
                down_energy_reserve[g.id] = Vector{VariableRef}(undef, N)
            end
        end
    end

    return SimpleBattery(power, sources, state_of_charge, up_capacity, 
    down_capacity, up_activation, down_activation, up_energy_reserve, down_energy_reserve, b["capacity"], b["initial_charge"], b["max_charge"], b["max_discharge"],
     class, b["id"])
end

# - Generation -
function build_aggregatorx_object(gt::Type{Generation}, g::Dict{String, Any}, aggregator::Dict{String,Any})
    N = aggregator["TimeStruct"].periods
    connections = aggregator["Connection"]
    
    id = g["id"]
    pmax = parse_data(g["pmax"],aggregator)
    pmin = parse_data(g["pmin"],aggregator)

    power = Dict{Integer, Vector{VariableRef}}()
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}(undef,N)
        end
    end

    return Generation(power, pmax, pmin, id)
end

# FixedLoad
function build_aggregatorx_object(t::Type{FixedLoad}, l::Dict{String, Any}, aggregator::Dict{String,Any})
    
    connections = aggregator["Connection"]
    id = l["id"]
    N = aggregator["TimeStruct"].periods
    
    source = 0
    for c in connections
        if c.sink == id
            source =  c.source
        end
    end
    
    load = parse_data(l["load"], aggregator)
    
    #if length(l["load"]) == 1
    #    load = parse_data(l["load"], N)
    #else
    #    load = parse_data(l["load"])
    #end

    constraint          = Dict{String, Vector{ConstraintRef}}()
    scalar_constraint   = Dict{String, ConstraintRef}()

    return FixedLoad(source, load, constraint, scalar_constraint, id)
end

# VariableLoad
function build_aggregatorx_object(t::Type{VariableLoad},l::Dict{String, Any}, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods
    connections = aggregator["Connection"]
    id = l["id"]

    power = Dict{Integer, Vector{VariableRef}}()

    sources = Vector{Int}(undef,0)
    has_output = 0
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}(undef, N)
            has_output = has_output + 1
        elseif c.sink == id
            push!(sources, c.source)
        end
    end

    if has_output > 1
        # should throw an error
    end

    if has_output == 0 # if no market connected to output
        power[0] = Vector{VariableRef}(undef, N)
    end

    lower_bound = Vector{Real}(undef, N)
    if isa(l["lower_bound"], Real) # Single number in system description
        lower_bound = l["lower_bound"] * ones(N)
    elseif isa(l["lower_bound"], Vector{Any}) # if system description is a vector
        lower_bound = l["lower_bound"]
    # elseif code if system description is string representing a file.
    # else error/infinity unbounded
    end

    upper_bound = Vector{Real}(undef, N)
    if isa(l["upper_bound"], Real)
        upper_bound = l["upper_bound"] * ones(N)
    elseif isa(l["upper_bound"], Vector{Any}) # if system description is a vector
        upper_bound = l["upper_bound"]
    # else code if system description is string representing a file.
    # else error/infinity unbounded
    end

    return VariableLoad(power, sources, lower_bound, upper_bound, id)
end

function build_aggregatorx_object(lt::Type{ThermalLoad}, l::Dict{String, Any}, aggregator::Dict{String,Any})
    N = aggregator["TimeStruct"].periods
    connections = aggregator["Connection"]

    power = Vector{AffExpr}()
    
    load = parse_data(l["load"])    
    if length(load) != N
        throw(MismatchedSystemException)
    end
    
    up_capacity         = Dict{Integer, Vector{VariableRef}}()
    down_capacity       = Dict{Integer, Vector{VariableRef}}()
    up_activation       = Dict{Integer, Vector{VariableRef}}()
    down_activation     = Dict{Integer, Vector{VariableRef}}()
    up_energy_reserve   = Dict{Integer, Vector{VariableRef}}()
    down_energy_reserve = Dict{Integer, Vector{VariableRef}}()
    
    temperature         = Vector{VariableRef}(undef,N)

    inital_temperature      = l["inital_temperature"]
    max_temperature         = l["max_temperature"]
    min_temperature         = l["min_temperature"]
    ambient_temperature     = parse_data(l["ambient_temperature"], aggregator)

    heat_capacity       = l["heat_capacity"]
    heat_loss_factor    = l["heat_loss_factor"]
    max_power           = l["max_power"]

    constraints = Vector{Any}()
    id = l["id"]
    source = getsource(id,connections)

    if haskey(aggregator, "Group")
        groups = aggregator["Group"]        
        for g in groups
            if id in g.resources # For each group add an entry in det capacity and activation dictionaries                 
                up_activation[g.id] = Vector{VariableRef}(undef, N)
                down_activation[g.id] = Vector{VariableRef}(undef, N)
                up_capacity[g.id] = Vector{VariableRef}(undef, N)
                down_capacity[g.id] = Vector{VariableRef}(undef, N)
                up_energy_reserve[g.id] = Vector{VariableRef}(undef, N)
                down_energy_reserve[g.id] = Vector{VariableRef}(undef, N)
            end
        end
    end

    return ThermalLoad(power, load, up_capacity, down_capacity, up_activation, 
        down_activation, up_energy_reserve, down_energy_reserve, temperature,
        inital_temperature, max_temperature, min_temperature, ambient_temperature, 
        heat_capacity, heat_loss_factor, max_power, constraints, source, id
        )
end

# - MinLoad - !Not tested!
function build_aggregatorx_object(lt::Type{MinLoad}, l::Dict{String, Any}, aggregator::Dict{String,Any})

    connections = aggregator["Connection"]
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
function build_aggregatorx_object(lt::Type{MinAverageLoad}, l::Dict{String, Any}, aggregator::Dict{String,Any})
    return MinAverageLoad(l["pmin"],l["id"])
end

# ------------
# - Grids -
# ------------
function build_aggregatorx_object(gt::Type{LinearTariff}, g::Dict{String, Any}, aggregator::Dict{String,Any})
    connections = aggregator["Connection"]
    N = aggregator["TimeStruct"].periods
    id = g["id"]
    
    power = Dict{Integer,Vector{VariableRef}}()
    sources = Vector{Integer}(undef,0)
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}(undef,N)
        end
        if c.sink == id
            push!(sources, c.source)
        end
    end

    #price = parse_data(g["price"])

    price = parse_data(g["price"], aggregator)

    #if length(g["price"]) == 1
    #    price = parse_data(g["price"], N)
    #else
    #    price = parse_data(g["price"])
    #end

    #upper_bound = g["upper_bound"]
    upper_bound = parse_data(g["upper_bound"], aggregator)

    #if length(g["upper_bound"]) == 1
    #    upper_bound = parse_data(g["upper_bound"], N)
    #else
    #    upper_bound = parse_data(g["upper_bound"])
    #end

    return LinearTariff(power, sources, price, upper_bound, id)
end

# ------------
# - Markets -
# ------------

# SimpleMarket
function build_aggregatorx_object(mt::Type{SimpleMarket}, m::Dict{String, Any}, aggregator::Dict{String,Any})

    connections = aggregator["Connection"]
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

    #price = parse_data(m["price"])
    price = parse_data(m["price"],aggregator)

    class = get_class(m)

    return SimpleMarket(power, price, resource, sign, class , id)
end

# - SimpleDAMarket
function build_aggregatorx_object(t::Type{SimpleDAMarket}, m::Dict{String, Any}, aggregator::Dict{String,Any})

    connections = aggregator["Connection"]

    id = m["id"]
    resource = -1
    for c in connections
        if c.source == id
            resource = c.sink
        end
    end

    power = Dict(resource => Vector{VariableRef}())

    class = get_class(m)

    #price = parse_data(m["price"])
    price = parse_data(m["price"],aggregator)
    
    return SimpleDAMarket(power, price, resource, m["sign"], class,  id)
end

# - FFRProfil -
function build_aggregatorx_object(t::Type{FFRProfil}, m::Dict{String, Any}, aggregator::Dict{String,Any})

    N = aggregator["TimeStruct"].periods

    price = ones(N) * m["price"]

    if haskey(m, "minimum_bid")
        minimum_bid = m["minimum_bid"]
    else
        minimum_bid = Inf
    end

    participating = nothing

    up_capacity_common = nothing
    up_capacity = init_expr_array(N)

    #armed = parse_data(m["armed"])
    armed = parse_data(m["armed"],aggregator)

    constraints = Dict{String, Vector{ConstraintRef}}()
    scalar_constraints = Dict{String, ConstraintRef}()

    return FFRProfil(up_capacity_common, up_capacity, price, minimum_bid, participating, armed, constraints, scalar_constraints, m["sign"], m["class"],  m["id"])
end

# - FCRN
function build_aggregatorx_object(t::Type{FCRN}, m::Dict{String, Any}, aggregator::Dict{String,Any})

    up_capacity = Vector{VariableRef}()
    down_capacity = Vector{VariableRef}()
    up_activation = Vector{VariableRef}()
    down_activation = Vector{VariableRef}()

    return FCRN(up_capacity, down_capacity, up_activation, down_activation, m["price_capacity"], m["price_up_activation"], m["price_down_activation"],
     m["df"], m["dfmax"], m["sign"], m["class"], m["id"])

end

# - FCRNe
function build_aggregatorx_object(t::Type{FCRNe}, m::Dict{String, Any}, 
    aggregator::Dict{String,Any})

    energy_endurance = m["energy_endurance"]
    capacity_factor = m["capacity_factor"]
    #price = parse_data(m["price"])
    price = parse_data(m["price"],aggregator)
    sign = m["sign"]
    id = m["id"]

    capacity_sold = Vector{VariableRef}()

    up_capacity         = Vector{AffExpr}()
    down_capacity       = Vector{AffExpr}()
    up_capacity_sold    = Vector{AffExpr}()
    down_capacity_sold  = Vector{AffExpr}()
    up_energy_reserve   = Vector{AffExpr}()
    down_energy_reserve = Vector{AffExpr}()

    return FCRNe(capacity_sold, up_capacity, down_capacity, up_capacity_sold, down_capacity_sold,
    up_energy_reserve, down_energy_reserve, energy_endurance, capacity_factor, price, sign, id)
end

function build_aggregatorx_object(t::Type{FCRD_Up_LER}, m::Dict{String, Any}, aggregator::Dict{String,Any})
    
    energy_endurance = m["energy_endurance"]
    capacity_factor = m["capacity_factor"]
    #price = parse_data(m["price"])
    price = parse_data(m["price"],aggregator)
    sign = m["sign"]
    id = m["id"]
    
    return FCRD_Up_LER(energy_endurance, capacity_factor, price, sign, id)
end

# -----------
# - Groups -
#------------

function build_aggregatorx_object(gt::Type{FFRGroup}, g::Dict{String, Any})
    up_capacity = Vector{AffExpr}()

    markets = Set{Int}()    
    mlist = g["markets"] # vector of ids of markets group is connected to. Defined in system file.
    for m in mlist
        push!(markets, m)
    end

    resources = Set{Int}()
    rlist = g["resources"] # vector of ids of resources in group. Defined in system file.
    for r in rlist
        push!(resources, r)
    end

    # Set all parameters, including tech_class and id
    return FFRGroup(up_capacity, resources, markets, g["class"], g["id"])
end

function build_aggregatorx_object(gt::Type{FCRGroup}, g::Dict{String, Any})
    up_capacity = Vector{AffExpr}()
    down_capacity = Vector{AffExpr}()
    up_activation = Vector{AffExpr}()    
    down_activation = Vector{AffExpr}()

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
    return FCRGroup(up_capacity,down_capacity, up_activation,down_activation, resources, markets, g["class"], g["id"])
end

function  build_aggregatorx_object(gt::Type{FCReGroup}, g::Dict{String, Any})
    up_capacity = Vector{AffExpr}()
    down_capacity = Vector{AffExpr}()
    up_energy_reserve = Vector{AffExpr}()    
    down_energy_reserve = Vector{AffExpr}()
    up_energy_reserve_factor = 1 # default
    down_energy_reserve_factor = 1 # defualt
    
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

    return FCReGroup(up_capacity, down_capacity, up_energy_reserve, down_energy_reserve,
    up_energy_reserve_factor, down_energy_reserve_factor,
        resources, markets, g["id"])
end