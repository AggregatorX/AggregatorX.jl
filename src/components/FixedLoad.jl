function set_optimization_variables(model::Model, load::FixedLoad, timestruct::TimeStruct)
    # No variables need
end

function set_optimization_constraints(model::Model, load::FixedLoad, aggregator::Dict{String, Any})
    
    source = get_component(load.source, aggregator)

    base_name = "fixed-load-" * string(load.id) * "-f-" * string(source.id)

    c = set_constraint_equality(model, aggregator["TimeStruct"], source.power[load.id], load.load, base_name)

    load.constraint["energy_conservation"] = c

end