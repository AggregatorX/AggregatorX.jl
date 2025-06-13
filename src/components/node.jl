# Variables
function set_optimization_variables(model::Model, node::StandardNode, timestruct::TimeStruct)
    for k in keys(node.power)
        base_name = "p-StandardNode-" * string(node.id) * "-" * string(k)
        node.power[k] = set_variables_full_set(model, timestruct, base_name)
    end
end

# Constraints
function set_optimization_constraints(model::Model, node::StandardNode, aggregator::Dict{String, Any})
    N  = aggregator["TimeStruct"].periods
    id = node.id

    ts = aggregator["TimeStruct"]

    #power_out = init_expr_array(N)
    net_power = init_expr_array(N)
    #power_in  = init_expr_array(N)

    #for target in keys(node.power)        
    #    power_out = power_out + node.power[target]
    #end 

    power_out = sum_out(node, :power, ts)
        
    #for r in all_components(aggregator) # Resources, markets, nodes, grids
    #    if r.id in node.sources
    #        power_in = power_in + r.power[id]
    #    end
    #end

    power_in = sum_in(node, :power, ts, aggregator)

    #net_power = power_out-power_in # Energy conserved
    
    net_power = sum_expr(ts, power_out, -power_in)

    @constraint(model, net_power .== 0, base_name = "pnet-Standardode-" * string(id))
end