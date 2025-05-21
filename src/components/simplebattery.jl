function set_optimization_variables(model::Model, battery::SimpleBattery, 
    timestruct::TimeStruct) 

    # Output power
    for k in keys(battery.power)
        base_name = "p-SimpleBattery-" * string(battery.id) * "-" * string(k)
        battery.power[k] = set_variables_full_set(model, timestruct, base_name)
    end
    
    # State of charge
    base_name = "soc-SimpleBattery-" * string(battery.id)
    battery.state_of_charge =set_variables_full_set(model, timestruct, base_name)
    
    # Capacity    
    for k in keys(battery.up_capacity)
        base_name = "up-capacity-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.up_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_capacity)
        base_name = "down-capacity-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.down_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    # Activation
    for k in keys(battery.up_activation)
        base_name = "up-activation-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.up_activation[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_activation)
        base_name = "down-activation-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.down_activation[k] = set_variables_full_set(model, timestruct, base_name)
    end

    # Energy reserve
    for k in keys(battery.up_energy_reserve)
        base_name = "up-energy-reserve-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.up_energy_reserve[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_energy_reserve)
        base_name = "down-energy-reserve-SimpleBattery-" * string(battery.id) * "-group-" * string(k)
        battery.down_energy_reserve[k] = set_variables_full_set(model, timestruct,base_name)
    end
    
end

function set_optimization_constraints(model::Model, r::SimpleBattery, aggregator::Dict{String, Any})
    ts = aggregator["TimeStruct"]
    N = ts.periods
    id = r.id
    
    # Convenience variables
    power_out = init_expr_array(N)
    for target in keys(r.power)
        power_out = power_out + r.power[target]
    end 
    
    power_in = init_expr_array(N)
    sources = r.sources
    for r in all_components(aggregator) # union(aggregator["Resource"], aggregator["Market"])
        if r.id in sources
            power_in = power_in + r.power[id]
        end
    end

    net_power = init_expr_array(N)
    net_power = power_out - power_in # Net outflow is defined as positive

    # Activation
    total_up_activation = init_expr_array(N)
    for k in keys(r.up_activation)
        total_up_activation = total_up_activation + r.up_activation[k]
    end

    total_down_activation = init_expr_array(N)
    for k in keys(r.down_activation)
        total_down_activation = total_down_activation + r.down_activation[k]
    end

    net_activation = init_expr_array(N)
    net_activation = total_up_activation - total_down_activation # Positive for net power out, that is, up-regulation

    # Total flow
    delta = init_expr_array(N)
    delta = delta - (net_power + net_activation) # net outflow is positive

    # - Constraints -

    # Inital value
    base_name = "soc-init-SimpleBattery" * string(id)
    set_constraint_initial_value(model, ts, r.state_of_charge, r.initial_charge, base_name)
    
    # Energy conserved: Change in state of charge equal net power flow
    base_name = "soc-SimpleBattery-" * string(id)
    set_constraint_temporal_evolution(model, ts , r.state_of_charge, delta, base_name)
    
    # max charge
    base_name ="max-soc-SimpleBattery" * string(id)
    set_constraint_upper_bound(model, ts, r.state_of_charge, r.capacity, base_name)

    base_name ="max-soc_last-SimpleBattery" * string(id) # ... last time step
    c = set_constraint_upper_bound_last(model, ts, r.state_of_charge, delta, r.capacity, base_name)

    # min charge
    base_name ="max-soc-SimpleBattery" * string(id)
    set_constraint_lower_bound(model, ts, r.state_of_charge, 0.0, base_name)

    base_name ="min-soc-last-SimpleBattery" * string(id) # ... last time step
    set_constraint_lower_bound_last(model, ts, r.state_of_charge, delta, 0.0, base_name)

    # charge/discharge rates
    @constraint(model, power_out + total_up_activation .<= r.max_discharge, base_name ="max-discharging-SimpleBattery" * string(id))
    @constraint(model, power_in + total_down_activation .<= r.max_charge, base_name ="max-charging-SimpleBattery" * string(id))

    total_up_capacity = init_expr_array(N)
    for k in keys(r.up_capacity)
        total_up_capacity = total_up_capacity + r.up_capacity[k]
    end

    total_down_capacity = init_expr_array(N)
    for k in keys(r.down_capacity)
        total_down_capacity = total_down_capacity + r.down_capacity[k]
    end

    # Capacity for up/down regulation. Flow constrained
    if !(isempty(r.up_capacity)) # Empty if not part of group
        @constraint(model, total_up_capacity <= r.max_discharge .- power_out .+ power_in, base_name="max-up-capacity-SimpleBattery-" * string(id))
    end
    if !(isempty(r.down_capacity))
        @constraint(model, total_down_capacity <= r.max_charge .- power_in .+ power_out, base_name="max-down-capacity-SimpleBattery-" * string(id) )
    end

    # Capacity for up/down regulation. SoC constrained
    #if ( !(isempty(r.up_capacity)) & !(isempty(r.down_capacity)) )
    #    @constraint(model, r.state_of_charge - net_power + total_down_capacity .<= r.capacity, base_name ="capacity-max-soc-SimpleBattery-" * string(id))
    #    @constraint(model, r.state_of_charge - net_power - total_up_capacity .>= 0.0, base_name ="capacity-min-soc-SimpleBattery-" * string(id))
    #end

    # Energy reserve
    if (!(isempty(r.up_energy_reserve)))
        total_up_energy_reserve = init_expr_array(N)
        total_down_energy_reserve = init_expr_array(N)
        for k in keys(r.up_energy_reserve)
            total_up_energy_reserve = total_up_energy_reserve + r.up_energy_reserve[k]
            total_down_energy_reserve = total_down_energy_reserve + r.down_energy_reserve[k]
        end
        @constraint(model, r.state_of_charge >= total_up_energy_reserve, base_name = "up-energy-reserve-SimpleBattery-" * string(id) )
        @constraint(model, r.capacity .- r.state_of_charge >= total_down_energy_reserve, base_name = "down-energy-reserve-SimpleBattery-" * string(id) )
    end
    # We have implicitly assumed here that power_out and power_in are not simultaneously
    # non-zero. The program should throw a warning if this occurs and this should be considered
    # a case that the software does not handle or an indication of the possibility of A
    # modelling error.
end