#module OptimizeAggregator

#using JuMP

#include("AggregatorXComponents.jl")
#include("AggregatorXmethods.jl")

#export optimizeaggregator

function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    
    #for i,l in loads
    # 

    # Set up variables
    # standard for all
    @variable(model, p_load[1:length(aggregator["Load"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_grid[1:length(aggregator["Grid"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_market[1:length(aggregator["Market"]), 1:aggregator["TimeStruct"].periods])

    # map index to component id
    loads = aggregator["Load"]
    load_id_map = Vector{Int}(undef, length(loads))
    for (i,load) in enumerate(loads)
        load_id_map[i] = load.id
    end
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

    #@objective(model, min, sum( sum(p_grid[i,t].*c_grid[i,t]) ))

    # Set up constraints

    # Optimize
    return model
end

# These are used for each load if there are additional variables to be defined depending on type
function set_optimization_variables(model::Model, load::MinAverageLoad, timestruct::TimeStruct) 
    # return charge, charging, discharging
    @variable(model, p_load[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

#end