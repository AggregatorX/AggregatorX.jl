#module OptimizeAggregator

#using JuMP

#include("AggregatorXComponents.jl")
#include("AggregatorXmethods.jl")

#export optimizeaggregator

function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    
    timestruct = aggregator["TimeStruct"]
    N = timestruct.periods

    # -- Variables --

    categories = ["Load", "Grid", "Market"]

    #  - Standard 'external variables' -
    @variable(model, p_load[1:length(aggregator["Load"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_grid[1:length(aggregator["Grid"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_market[1:length(aggregator["Market"]), 1:aggregator["TimeStruct"].periods])
    
    id_map = idx_to_id(aggregator, categories) # map component index to component id: id = id_map["component"][idx] 

    # - Interconnection variables -
    # ic_varref is a vector where each item is a variable (really vector of variables over time) that represents 
    # an interconnection.
    # Resource ids are found by accesing the "Interconnection" vector in the aggregator with same index.
    # The id is also indicated in the name of the variable for easier printing
    ics = aggregator["Connection"]["Interconnection"]
    ic_varref = Vector{Vector{VariableRef}}(undef,length(ics))
    for (i,ic) in enumerate(ics)
        source = ic.source
        sink = ic.sink
        icref = @variable(model, [1:N])
        ic_varref[i] = icref
        for j in 1:N
            set_name(icref[j], "p_ic-" * string(source) * "-" * string(sink) * "[" * string(j) * "]" )
        end
    end

    # - Resource dependent variables -
    categories = ["Resource"] # Also variables for external components?
    for category in categories
        for component in aggregator[category]  
            set_optimization_variables(model, component, aggregator["TimeStruct"])                      
        end
    end

    # Markets
    markets = aggregator["Market"]
    for m in markets
        if isa(m, SimpleDAMarket)
            set_optimization_variables(model, m, aggregator["TimeStruct"])
        end        
    end

    # - Group variables - 
    # For each group define available capacity to be reserved
    up_capacity, down_capacity = set_optimization_variables(model, aggregator["Group"], aggregator["TimeStruct"])

    # --- Constraints ---
    for group in aggregator["Group"]
        set_optimization_constraints(model, group, aggregator["TimeStruct"])
    end

    # - External component constraints -
    category = "Load"
    loads = aggregator[category]
    for (i,load) in enumerate(loads)
        set_optimization_constraints(model, load, i, timestruct)
        #@constraint(model, c, sum(p_load[i,1:N]) >= load.pmin) # specific for MinAverageLoad, put into method
    end

    # Grid
    #category = "Grid"
    #for grid in aggregator[category]

    # - Resource specific constraints - 
    # As a minimum energy conservation for all connected components
    category = "Resource"
    resources = aggregator[category]
    for r in resources # For every resource
        if isa(r,SimpleCharger) # Only this implemented so far
            set_optimization_constraints(model, aggregator, r, id_map, ic_varref)
        end
    end
    # Find grid connection
    
    grids = aggregator["Grid"]
    cost_grid = Array{AbstractFloat,2}(undef,length(grids),N)
    for (i,g) in enumerate(grids)
        cost_grid[i,1:N] = g.price
    end

    markets = aggregator["Market"]
    cost_market = Array{AbstractFloat,2}(undef,length(markets),N)
    for (i,m) in enumerate(markets)
        cost_market[i,1:N] = m.price
    end
    @objective(model, Min, sum( sum(p_grid.*cost_grid) ) - sum( sum(p_market.*cost_market) ) )

    # Internal properties, storage, loss, production
    # p_load(i,t) + pij + p-market = pji + p_grid

    # -- Objective function --
   #=
    z = AffExpr()

    
    # - Grid -    
    id_grids = id_map["Grid"]
    for i in 1:length(aggregator["Grid"])
        id = id_grids[i]
        grid = aggregator["Grid"][i]
        c = grid.price 
        expr = @expression(model, sum(p_grid[i,t].*c[t] for t in 1:N))
        add_to_expression!(z, expr)
    end

    # - Load -    
    # id_loads = id_map("Load")
    # for i in length(aggregator["Load"])
    # id = id_loads(i)
    # load = aggregator["Load"][i]
    # c = load.price # Some functionality if "free", no price
    # expr = @expression(sum(p_load[i,t]*c[t] for t in [1:N]))
    # add_to_expression(z,expr)
    # end

    # - Market 
    id_markets = id_map["Market"]
    for i in 1:length(aggregator["Market"])
        id = id_markets[i]
        market = aggregator["Market"][i]
        c = market.price
        expr = @expression(model, sum(p_market[i,t]*c[t] for t in 1:N))
        add_to_expression!(z,-expr)
    end
    =#
    z = set_objective(model, aggregator)
    @objective(model, Min, z)
    # Optimize
    # optimize!(model)

    return model
end

function set_optimization_constraints(model::Model, aggregator::Dict{String, Any} , resource::SimpleBattery, id_map::Dict{String, Any}, ic_varref::Any)
    timestruct = aggregator["TimeStruct"]
    
    N = timestruct.periods

    id = resource.id
    # Constrained by energy balance
    # Check all connections, 
    c = aggregator["Connection"]

    ras = c["ResourceToAggregator"]
    for ra in ras
        if ra.resource == id
            # Add this to energy balance
        end

    end
    # Resource to aggregator




    # Constrained by charging capacity


end

function set_optimization_constraints(model::Model, aggregator::Dict{String, Any} , resource::SimpleCharger, id_map::Dict{String, Any}, ic_varref::Any)
    timestruct = aggregator["TimeStruct"]
    
    N = timestruct.periods

    id = resource.id
    
    # Connected loads
    load_id_map = id_map["Load"]
    rls = aggregator["Connection"]["ResourceToLoad"]
    idx = Vector{Int}() # Multiple loads per resource allowed
    for rl in rls 
        if rl.resource == id
            load_id = rl.load
            idx = push!(idx, findfirst(x->x==load_id, load_id_map)) # index of load used in constraint
        end
    end

    # Connected grids. Assume only one resource connected to each grid
    grid_id_map = id_map["Grid"]
    grs = aggregator["Connection"]["GridToResource"]
    for gr in grs
        if gr.resource == id
            grid_id = gr.grid
            idx = findfirst(x->x==grid_id, grid_id_map)
        end
    end

    # Connected components
    ics = aggregator["Connection"]["Interconnection"]
    p_ic = Vector{AffExpr}(undef,N) # Should this be a variable
    for i in eachindex(p_ic)
        p_ic[i] = AffExpr(0.0)
    end
    
    for (i,ic) in enumerate(ics)
        icref = ic_varref[i]
        source = ic.source
        sink = ic.sink        
        if source == id
            # add
            
            term = @expression(model, ic_term, 1.0*icref)
            
            for (a,b) in zip(p_ic,term)
                
                add_to_expression!(a,b)            
            end
            
        elseif sink == id
            # subtract
            term = @expression(model, ic_term, -icref)
            add_to_expression!(p_ic, 1.0, term)
            for (a,b) in zip(p_ic,term)
                add_to_expression!(a,b)
            end
        end
    end
    c = @constraint(model, [t in 1:timestruct.periods], 
        sum(model[:p_load][i,t] for i in idx) - model[:p_grid][idx,t] + p_ic[t]  == 0)
end

function set_objective(model::Model, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods

    markets = aggregator["Market"]
    
    z = 0 
    for m in markets
        if isa(m, SimpleDAMarket)
        z = z + sum(m.power .* m.price)
        end
    end

    return z
end

