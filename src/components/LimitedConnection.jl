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
    
    # Check potential power flow due to capacity activation and activation bids
    total_in = init_expr_array_full(aggregator["TimeStruct"])
    total_out = init_expr_array_full(aggregator["TimeStruct"])
    
    total_in = total_in .+ lc.power[target]
    total_out = total_out .- lc.power[target]
    
    for cm_id ∈ lc.capacity_markets
        cm = get_component(cm_id, aggregator)
        if hasproperty(cm, :up_capacity_sold)
            total_in = total_in .+ cm.down_capacity_sold # if capcity factor
            total_out = total_out .+ cm.up_capacity_sold
        else
            total_in = total_in .+ cm.down_capacity
            total_out = total_out .+ cm.up_capacity
        end
    end

    # TODO: Add direct activation markets

    @constraint(model, total_in <= lc.upper_bound, base_name = "pmax_$identifier")
    @constraint(model, total_out <= lc.upper_bound, base_name = "pmax_$identifier")
end

#function get_objective_term(g::LimitedConnection)
    # adds no terms to objective function
#end