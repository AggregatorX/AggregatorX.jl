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
    #categories = ["Load", "Grid", "Market"]
    loads = aggregator["Load"]
    load_id_map = Vector{Int}(undef, length(loads))
    for (i,load) in enumerate(loads)
        load_id_map[i] = load.id
    end
    # idx_id_map["Load"] = load_id_map etc
    #load_id_map


    
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

    # Set up objective function
    # Minimize cost
    # sum_t f(p)
    # expr: sum(fun,itr)

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
            set_optimization_constraints(model, aggregator, r, load_id_map)
        end
    end
    # Find grid connection
    
    # Find Interconnections
    # Find aggregator connections
    # Internal properties, storage, loss, production
    # p_load(i,t) + pij + p-market = pji + p_grid


    # Optimize
    return model
end

function set_optimization_constraints(model::Model, aggregator::Dict{String, Any} , resource::SimpleCharger, id_map::Vector{Int})
    timestruct = aggregator["TimeStruct"]
    
    id = resource.id
    load_id_map = id_map # for mulitple maps later

    # Connected loads
    rls = aggregator["Connection"]["ResourceToLoad"]
    idx = Vector{Int}()
    for rl in rls 
        if rl.resource == id
            load_id = rl.load
            idx = push!(idx, findfirst(x->x==load_id, load_id_map)) # index of load used in constraint
        end
    end
    # Connected grids
    
    @constraint(model, [t in 1:timestruct.periods], sum(model[:p_load][i,t] for i in idx) == 0)
end

# These are used for each load if there are additional variables to be defined depending on type
function set_optimization_variables(model::Model, load::MinAverageLoad, timestruct::TimeStruct) 
    # return charge, charging, discharging
    @variable(model, p_load[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

#end