function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    set_attribute(model, "output_flag", false)
    
    timestruct = aggregator["TimeStruct"]
    N = timestruct.periods

    # -- Variables --

    # Resources
    for component in aggregator["Resource"]  
        set_optimization_variables(model, component, aggregator["TimeStruct"])                      
    end

    # Groups
    if haskey(aggregator,"Grid")
        for g in aggregator["Grid"]
            set_optimization_variables(model, g, aggregator["TimeStruct"])
        end
    end
    
    # Markets
    markets = aggregator["Market"]
    for m in markets
        set_optimization_variables(model, m, aggregator["TimeStruct"])
    end 

    # Groups
    if haskey(aggregator,"Group")
        for g in aggregator["Group"]
            set_optimization_variables(model, g, aggregator["TimeStruct"])
        end
    end

    # Nodes 
    nodes = aggregator["Node"]
    for n in nodes
        set_optimization_variables(model, n, aggregator["TimeStruct"]) 
    end

    # Grids
    if haskey(aggregator, "Grid")
        for g in aggregator["Grid"]
            set_optimization_variables(model, g, aggregator["TimeStruct"])
        end
    end

    # --- Constraints ---

    # Markets
    for m in aggregator["Market"]
        set_optimization_constraints(model, m, aggregator)
    end
    
    # Groups
    if haskey(aggregator,"Group")
        for group in aggregator["Group"]
            set_optimization_constraints(model, group, aggregator)
        end
    end

    # Resources
    for r in aggregator["Resource"] # For every resource
        set_optimization_constraints(model, r, aggregator)
    end

    # Groups
    if haskey(aggregator,"Grid")
        for g in aggregator["Grid"]
            set_optimization_constraints(model, g, aggregator)
        end
    end

    # Nodes 
    nodes = aggregator["Node"]
    for n in nodes
        set_optimization_constraints(model, n, aggregator) 
    end

    # --- Objective function ---
    z = set_objective(model, aggregator)
    @objective(model, Max, z)

    # Optimize
    optimize!(model)

    return model
end