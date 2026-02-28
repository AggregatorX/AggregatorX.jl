function set_optimization_variables(model, g::LinearTariff, timestruct::TimeStruct)
    N = timestruct.periods
    for k in keys(g.power)
        g.power[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-Grid-" * string(g.id))
    end
end

function set_optimization_constraints(model::Model, g::LinearTariff, aggregator::Dict{String, Any})
    source = get_component(g.sources[1], aggregator)
    target = collect(keys(g.power))[1]
    
    @constraint(model, g.power[target] == source.power[g.id], base_name = "pnet-LinearTariff" * string(g.id))

    @constraint(model, g.power[target] <= g.upper_bound, base_name = "pmax-LinearTariff" * string(g.id))
end

function get_objective_term(g::LinearTariff)
    target = collect(keys(g.power))[1]
    zterm = sum(-g.price .* g.power[target])
end