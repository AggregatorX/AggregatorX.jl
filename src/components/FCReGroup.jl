function set_optimization_variables(model::Model, group::FCReGroup, timestruct::TimeStruct)
    # Only intermediate variables used for this group
end

function set_optimization_constraints(model::Model, group::FCReGroup, aggregator::Dict{String, Any})
    ts = aggregator["TimeStruct"] 
    N = aggregator["TimeStruct"].periods

    # - Reserved capacity -

    # Group capacity is is capacity of sum of capacity of individual resources
    #total_up_capacity_available = init_expr_array(N)
    #total_down_capacity_available = init_expr_array(N)
    total_up_capacity_available = init_expr_array_full(ts)
    total_down_capacity_available = init_expr_array_full(ts)

    for id in group.resources
        r = get_component(id, aggregator)
        total_up_capacity_available = total_up_capacity_available + r.up_capacity[group.id]
        total_down_capacity_available = total_down_capacity_available + r.down_capacity[group.id]
    end

    group.up_capacity = total_up_capacity_available
    group.down_capacity = total_down_capacity_available

    # Capacity sold to markets is limited by available capacity
    total_up_capacity_reserved = init_expr_array(N)
    total_down_capacity_reserved = init_expr_array(N)

    for id in group.markets
        m = get_component(id, aggregator)    
        total_up_capacity_reserved = total_up_capacity_reserved + m.up_capacity
        total_down_capacity_reserved = total_down_capacity_reserved + m.down_capacity
    end
    
    @constraint(model, total_up_capacity_reserved <= group.up_capacity, base_name = "up-capacity-limit-FCReGroup" * string(group.id))
    @constraint(model, total_down_capacity_reserved <= group.down_capacity, base_name = "down-capacity-limit-FCReGroup" * string(group.id))

    # - Activation -

    # This FCR group assumes no activation. This constraint ensures that the resources
    # does not contribute activation to this group. Without any constraint on this
    # variable, the resources could freely set the value of their activation parameter,
    # and e.g. down-activate and freely get energy from 'nowhere'.
    for id in group.resources
        r = get_component(id,aggregator)
        @constraint(model, r.up_activation[group.id] == 0, base_name = "no-activation-FCReGroup" * string(group.id))
        @constraint(model, r.down_activation[group.id] == 0, base_name = "no-activation-FCReGroup" * string(group.id))
    end

    # - Energy reserves -

    # Set energy_endurance to maximum of connected markets
    energy_endurance = 0
    for id in group.markets
        m = get_component(id, aggregator)
        energy_endurance = max(energy_endurance, m.energy_endurance)
    end

    # Set energy reserve requirement individually for each connected resource in the group.
    for id in group.resources
        r = get_component(id,aggregator)
        base_name = "up-energy-reserve-FCReGroup-" * string(group.id) * "r" * string(id)
        @constraint(model, r.up_energy_reserve[group.id] >= energy_endurance * r.up_capacity[group.id], base_name = base_name)

        base_name = "down-energy-reserve-FCReGroup-" * string(group.id) * "r" * string(id)
        @constraint(model, r.down_energy_reserve[group.id] >= energy_endurance * r.down_capacity[group.id], base_name = base_name)
    end
    
end