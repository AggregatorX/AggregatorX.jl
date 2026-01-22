function set_optimization_variables(model::Model, battery::SimpleBatteryVarParam, 
    timestruct::TimeStruct) 

    # Output power
    for k in keys(battery.power)
        base_name = "p-SimpleBatteryVarParam-" * string(battery.id) * "-" * string(k)
        battery.power[k] = set_variables_full_set(model, timestruct, base_name)
    end
    
    # State of charge
    base_name = "soc-SimpleBatteryVarParam-" * string(battery.id)
    battery.state_of_charge =set_variables_full_set(model, timestruct, base_name)
   
    # Capacity    
    for k in keys(battery.up_capacity)
        base_name = "up-capacity-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.up_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_capacity)
        base_name = "down-capacity-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.down_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    # Activation
    for k in keys(battery.up_activation)
        base_name = "up-activation-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.up_activation[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_activation)
        base_name = "down-activation-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.down_activation[k] = set_variables_full_set(model, timestruct, base_name)
    end

    # Energy reserve
    for k in keys(battery.up_energy_reserve)
        base_name = "up-energy-reserve-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.up_energy_reserve[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_energy_reserve)
        base_name = "down-energy-reserve-SimpleBatteryVarParam-" * string(battery.id) * "-group-" * string(k)
        battery.down_energy_reserve[k] = set_variables_full_set(model, timestruct,base_name)
    end
    
end

function set_optimization_constraints(model::Model, r::SimpleBatteryVarParam, aggregator::Dict{String, Any})
    ts = aggregator["TimeStruct"]
    N = ts.periods
    id = r.id
    
    # - Convenience variables -

    # Input and output power without activation
    power_in = sum_in(r, :power, ts, aggregator)
    power_out = sum_out(r, :power, ts)     
    net_power = sum_expr(ts, power_out, -power_in) #Net outflow is defined as positive

    # Total up and down activation
    total_up_activation = sum_out(r, :up_activation, ts)
    total_down_activation = sum_out(r, :down_activation, ts)
    net_activation = sum_expr(ts, total_up_activation, -total_down_activation) #Positive for net power out, that is, up-regulation

    # Net power flow including activation
    total_out = sum_expr(ts, power_out, total_up_activation)
    total_in = sum_expr(ts, power_in, total_down_activation)
    delta = sum_expr(ts, -net_power, -net_activation) # Net inflow. Net INFLOW is defined as positive (i.e. increasing battery charge)!

    # - Constraints -

    # Inital value
    base_name = "soc-init-SimpleBattery" * string(id)
    set_constraint_initial_value(model, ts, r.state_of_charge, r.initial_charge, base_name)
    
    # Energy conservation. Change in state of charge equal net power flow
    base_name = "soc-SimpleBattery-" * string(id)
    set_constraint_temporal_evolution(model, ts , r.state_of_charge, delta, base_name)
    
    # Maximum/minimum state of charge
    base_name ="max-soc-SimpleBattery" * string(id)
    set_constraint_upper_bound(model, ts, r.state_of_charge, r.capacity, base_name)
    
    base_name ="max-soc_last-SimpleBattery" * string(id) # ... last time step
    c = set_constraint_upper_bound_last(model, ts, r.state_of_charge, delta, r.capacity[end], base_name)

    base_name ="min-soc-SimpleBattery" * string(id)
    set_constraint_lower_bound(model, ts, r.state_of_charge, 0.0, base_name)
    
    base_name ="min-soc-last-SimpleBattery" * string(id) # ... last time step
    set_constraint_lower_bound_last(model, ts, r.state_of_charge, delta, 0.0, base_name)

    # Maximum charge/discharge rates
    base_name = "max-discharging-SimpleBattery" * string(id)
    set_constraint_upper_bound(model, ts, total_out, r.max_discharge, base_name)

    base_name = "max-charging-SimpleBattery" * string(id)
    set_constraint_upper_bound(model, ts, total_in, r.max_charge, base_name)

    # Capacity for up/down regulation. Flow constrained
    if !(isempty(r.up_capacity)) # Empty if not part of group
        total_up_capacity = sum_out(r, :up_capacity, ts)
        @constraint(model, total_up_capacity .<= r.max_discharge .- power_out .+ power_in, base_name="max-up-capacity-SimpleBattery-" * string(id))
    end
    if !(isempty(r.down_capacity))
        total_down_capacity = sum_out(r, :down_capacity, ts)
        @constraint(model, total_down_capacity .<= r.max_charge .- power_in .+ power_out, base_name="max-down-capacity-SimpleBattery-" * string(id) )
    end

    # Energy reserve
    if (!(isempty(r.up_energy_reserve)))
        total_up_energy_reserve = sum_out(r, :up_energy_reserve, ts)
        total_down_energy_reserve = sum_out(r, :down_energy_reserve, ts)
        
        if isa(ts, IndexedTimeStruct)
            @constraint(model, [i = 1:ts.periods], r.state_of_charge[i] >= total_up_energy_reserve[i], base_name = "up-energy-reserve-SimpleBattery-" * string(id) )
            @constraint(model, [i = 1:ts.periods], r.capacity[i] - r.state_of_charge[i] >= total_down_energy_reserve[i], base_name = "down-energy-reserve-SimpleBattery-" * string(id) )
        elseif isa(ts, StochasticTimeStruct)
            @constraint(model, [i = 1:ts.periods, j = ts.scenarios], r.state_of_charge[i,j] >= total_up_energy_reserve[i,j], base_name = "up-energy-reserve-SimpleBattery-" * string(id) )
            @constraint(model, [i = 1:ts.periods, j = ts.scenarios], r.capacity[i,j] - r.state_of_charge[i,j] >= total_down_energy_reserve[i,j], base_name = "down-energy-reserve-SimpleBattery-" * string(id) )
        end
    end
    
end

# No objective function contribution for SimpleBattery