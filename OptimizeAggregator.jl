module OptimizeAggregator

using JuMP

export optimizeaggregator

function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    # Set up variables

    # Set up objective function

    # Set up constraints

    # Optimize
    return model
end

end