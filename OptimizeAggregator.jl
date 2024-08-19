module OptimizeAggregator

using JuMP

export optimizeaggregator

function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    
    # Set up variables
    @variable(model, p_load[1:length(aggregator["Load"]), 1:aggregator["TimeStruct"].periods])
    @variable(model, p_grid[1:length(aggregator["Grid"]), 1:aggregator["TimeStruct"].periods])

    # Set up objective function

    # Set up constraints

    # Optimize
    return model
end

end