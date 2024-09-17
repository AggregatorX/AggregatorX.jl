function optimizeaggregator(aggregator, optimizer)

    model = Model(optimizer)
    set_attribute(model, "output_flag", false)
    
    timestruct = aggregator["TimeStruct"]
    N = timestruct.periods

    # -- Variables --

    #categories = [ "Grid", "Market"]
    #id_map = idx_to_id(aggregator, categories) # map component index to component id: id = id_map["component"][idx] 

    # Resources
    for component in aggregator["Resource"]  
        set_optimization_variables(model, component, aggregator["TimeStruct"])                      
    end
    
    # Markets
    markets = aggregator["Market"]
    for m in markets
        set_optimization_variables(model, m, aggregator["TimeStruct"])
    end 

    # Groups
    for g in aggregator["Group"]
        set_optimization_variables(model, g, aggregator["TimeStruct"])
    end

    # --- Constraints ---

    # Markets
    for m in aggregator["Market"]
        set_optimization_constraints(model, m, aggregator)
    end
    
    # Groups
    for group in aggregator["Group"]
        set_optimization_constraints(model, group, aggregator)
    end

    # Resources
    for r in aggregator["Resource"] # For every resource
        set_optimization_constraints(model, r, aggregator)
    end

    # --- Objective function ---
    z = set_objective(model, aggregator)
    @objective(model, Max, z)

    # Optimize
    optimize!(model)

    return model
end