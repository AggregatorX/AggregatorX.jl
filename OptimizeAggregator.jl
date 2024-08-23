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
    
    # Set up additional special variables
    # For each resource of particular type
    categories = ["Resource"]
    for category in categories
        for component in aggregator[category]
            println(string(typeof(component)) * "\n" * string(component isa SimpleBattery))
            if isa(component,SimpleBattery)
                set_optimization_variables(model, component, aggregator["TimeStruct"])
            end
        end
    end

    # Set up objective function

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