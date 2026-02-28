function set_optimization_variables(model::Model, lc::LimitedConnection, 
    timestruct::TimeStruct) 
    N = timestruct.periods
    for k in keys(lc.power)
        lc.power[k] = @variable(model, [1:N], lower_bound = 0.0, 
            base_name = "p-LimitedConnection-" * string(lc.id))
    end
end

function set_optimization_constraints(model::Model, lc::LimitedConnection, 
    aggregator::Dict{String, Any})
    source = get_component(lc.sources[1], aggregator)
    target = collect(keys(lc.power))[1]
    
    identifier = "LinearTariff_" * "string(lc.id)"
    
    @constraint(model, lc.power[target] == source.power[lc.id], base_name = "pnet_$identifier")
    @constraint(model, lc.power[target] <= lc.upper_bound, base_name = "pmax_$identifier")
end

function get_objective_term(g::LimitedConnection)
    # no additional terms to objective function
end