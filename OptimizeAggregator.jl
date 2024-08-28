#module OptimizeAggregator

#using JuMP

#include("AggregatorXComponents.jl")
#include("AggregatorXmethods.jl")

#export optimizeaggregator

function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    
    #for i,l in loads
    # 
    N = aggregator["TimeStruct"].periods

    # Set up variables
    # standard for all
    @variable(model, p_load[1:length(aggregator["Load"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_grid[1:length(aggregator["Grid"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_market[1:length(aggregator["Market"]), 1:aggregator["TimeStruct"].periods])

    # map index to component id # Maybe have a common for all the types. A dictionary
    id_map = Dict{String,Any}()
    categories = ["Load", "Grid", "Market"]
    for c in categories
        loads = aggregator[c]
        load_id_map = Vector{Int}(undef, length(loads))
        for (i,load) in enumerate(loads)
            load_id_map[i] = load.id
        end
        id_map[c] = load_id_map
    end
    #load_id_map

    # Set interconnection variables
    # Find Interconnections
    # Find aggregator connections
    # Connected components
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

    
    # Set up additional special variables
    # For each resource of particular type
    categories = ["Resource"]
    for category in categories
        for component in aggregator[category]            
            if isa(component,SimpleBattery)
                set_optimization_variables(model, component, aggregator["TimeStruct"])
            end
        end
    end

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

    # Set up constraints
    
    # Grid
    #category = "Grid"
    #for grid in aggregator[category]
    
    category = "Load"
    loads = aggregator[category]
    for (i,load) in enumerate(loads)
        @constraint(model, c, sum(p_load[i,1:N]) >= load.pmin) # specific for MinAverageLoad, put into method
    end

    # Interconnection constraints, i.e. energy conservation
    # Loop through every resource id
    category = "Resource"
    resources = aggregator[category]
    for r in resources
        if isa(r,SimpleCharger) # Only this implemented so far
            set_optimization_constraints(model, aggregator, r, id_map, ic_varref)
        end
    end
    # Find grid connection
    
    

    # Internal properties, storage, loss, production
    # p_load(i,t) + pij + p-market = pji + p_grid

    # -- Objective function --
    # Minimize cost
    # sum_t f(p)
    # expr: sum(fun,itr)
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
    p_ic = Vector{AffExpr}(undef,N)
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

# These are used for each load if there are additional variables to be defined depending on type
function set_optimization_variables(model::Model, load::MinAverageLoad, timestruct::TimeStruct) 
    # return charge, charging, discharging
    @variable(model, p_load[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

#end