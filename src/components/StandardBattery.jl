function set_optimization_variables(model, battery::StandardBattery, timestruct::TimeStruct)
    # Output power
    for k in keys(battery.power)
        base_name = "p-StandardBattery-" * string(battery.id) * "-" * string(k)
        battery.power[k] = set_variables_full_set(model, timestruct, base_name)
    end
    
    # State of charge
    base_name = "soc-StandardBattery-" * string(battery.id)
    battery.state_of_charge =set_variables_full_set(model, timestruct, base_name)
   
    # Capacity    
    for k in keys(battery.up_capacity)
        base_name = "up-capacity-StandardBattery-" * string(battery.id) * "-group-" * string(k)
        battery.up_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_capacity)
        base_name = "down-capacity-StandardBattery-" * string(battery.id) * "-group-" * string(k)
        battery.down_capacity[k] = set_variables_full_set(model, timestruct, base_name)
    end

    # Activation
    for k in keys(battery.up_activation)
        base_name = "up-activation-StandardBattery-" * string(battery.id) * "-group-" * string(k)
        battery.up_activation[k] = set_variables_full_set(model, timestruct, base_name)
    end

    for k in keys(battery.down_activation)
        base_name = "down-activation-StandardBattery-" * string(battery.id) * "-group-" * string(k)
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

    
function set_optimization_constraints(model::Model, r::StandardBattery, aggregator::Dict{String, Any})
    ts = aggregator["TimeStruct"]
    N = ts.periods
    id = r.id
    eta_out = r.discharging_loss
    eta_in = r.charging_loss
    throughput_cost = r.throughput_cost
    # Convenience variables

    #power_out = init_expr_array(N)
    #for target in keys(r.power)
    #    power_out = power_out + r.power[target]
    #end 
    power_out = sum_out(r, :power, ts)
    
    power_in = sum_in(r, :power, ts, aggregator)
    #power_in = init_expr_array(N)
    #sources = r.sources
    #for r in all_components(aggregator)
    #    if r.id in sources
    #        power_in = power_in + r.power[id]
    #    end
    #end

    #net_power = init_expr_array(N)
    #net_power = power_out - power_in # Net outflow is defined as positive
    net_power = sum_expr(ts, power_out/eta_out, -power_in*eta_in)

    # Activation
    #total_up_activation = init_expr_array(N)
    #for k in keys(r.up_activation)
    #    total_up_activation = total_up_activation + r.up_activation[k]
    #end
    total_up_activation = sum_out(r, :up_activation, ts)

    #total_down_activation = init_expr_array(N)
    #for k in keys(r.down_activation)
    #    total_down_activation = total_down_activation + r.down_activation[k]
    #end
    total_down_activation = sum_out(r, :down_activation, ts)

    #net_activation = init_expr_array(N)
    #net_activation = total_up_activation - total_down_activation # Positive for net power out, that is, up-regulation
    net_activation = sum_expr(ts, total_up_activation, -total_down_activation)


    # Total flow
    #delta = init_expr_array(N)
    #delta = delta - (net_power + net_activation) # net outflow is positive
    delta = sum_expr(ts, -net_power, -net_activation)

    # - Constraints -

    # Inital value
    base_name = "soc-init-StandarBattery" * string(id)
    set_constraint_initial_value(model, ts, r.state_of_charge, r.initial_charge, base_name)
    
    # Energy conserved: Change in state of charge equal net power flow
    base_name = "soc-StandardBattery-" * string(id)
    set_constraint_temporal_evolution(model, ts , r.state_of_charge, delta, base_name)
    
    # max charge
    base_name ="max-soc-StandardBattery" * string(id)
    set_constraint_upper_bound(model, ts, r.state_of_charge, r.capacity, base_name)

    base_name ="max-soc_last-StandardBattery" * string(id) # ... last time step
    c = set_constraint_upper_bound_last(model, ts, r.state_of_charge, delta, r.capacity, base_name)

    # min charge
    base_name ="min-soc-StandardBattery" * string(id)
    set_constraint_lower_bound(model, ts, r.state_of_charge, 0.0, base_name)

    base_name ="min-soc-last-StandardBattery" * string(id) # ... last time step
    set_constraint_lower_bound_last(model, ts, r.state_of_charge, delta, 0.0, base_name)

    # charge/discharge rates
    
    #@constraint(model, power_out + total_up_activation .<= r.max_discharge, base_name ="max-discharging-SimpleBattery" * string(id))
    base_name = "max-discharging-StandardBattery" * string(id)
    total_out = sum_expr(ts, power_out, total_up_activation)
    set_constraint_upper_bound(model, ts, total_out, r.max_discharge, base_name)

    #@constraint(model, power_in + total_down_activation .<= r.max_charge, base_name ="max-charging-SimpleBattery" * string(id))
    base_name = "max-charging-StandardBattery" * string(id)
    total_in = sum_expr(ts, power_in, total_down_activation)
    set_constraint_upper_bound(model, ts, total_in, r.max_charge, base_name)

    #total_up_capacity = init_expr_array(N)
    #for k in keys(r.up_capacity)
    #    total_up_capacity = total_up_capacity + r.up_capacity[k]
    #end

    total_up_capacity = sum_out(r, :up_capacity, ts)

    #total_down_capacity = init_expr_array(N)
    #for k in keys(r.down_capacity)
    #    total_down_capacity = total_down_capacity + r.down_capacity[k]
    #end

    total_down_capacity = sum_out(r, :down_capacity, ts)

    # Capacity for up/down regulation. Flow constrained
    if !(isempty(r.up_capacity)) # Empty if not part of group
        @constraint(model, total_up_capacity .<= r.max_discharge .- power_out .+ power_in, base_name="max-up-capacity-StandardBattery-" * string(id))
    end
    if !(isempty(r.down_capacity))
        @constraint(model, total_down_capacity .<= r.max_charge .- power_in .+ power_out, base_name="max-down-capacity-StandardBattery-" * string(id) )
    end

    # Capacity for up/down regulation. SoC constrained
    #if ( !(isempty(r.up_capacity)) & !(isempty(r.down_capacity)) )
    #    @constraint(model, r.state_of_charge - net_power + total_down_capacity .<= r.capacity, base_name ="capacity-max-soc-SimpleBattery-" * string(id))
    #    @constraint(model, r.state_of_charge - net_power - total_up_capacity .>= 0.0, base_name ="capacity-min-soc-SimpleBattery-" * string(id))
    #end

    # Energy reserve
    if (!(isempty(r.up_energy_reserve)))
        #total_up_energy_reserve = init_expr_array(N)
        #total_down_energy_reserve = init_expr_array(N)
        #for k in keys(r.up_energy_reserve)
        #    total_up_energy_reserve = total_up_energy_reserve + r.up_energy_reserve[k]
        #    total_down_energy_reserve = total_down_energy_reserve + r.down_energy_reserve[k]
        #end
        total_up_energy_reserve = sum_out(r, :up_energy_reserve, ts)
        total_down_energy_reserve = sum_out(r, :down_energy_reserve, ts)
        
        if isa(ts, IndexedTimeStruct)
            @constraint(model, [i = 1:ts.periods], r.state_of_charge[i] >= total_up_energy_reserve[i], base_name = "up-energy-reserve-StandardBattery-" * string(id) )
            #@constraint(model, r.state_of_charge .>= total_up_energy_reserve, base_name = "up-energy-reserve-SimpleBattery-" * string(id) )
            @constraint(model, [i = 1:ts.periods], r.capacity - r.state_of_charge[i] >= total_down_energy_reserve[i], base_name = "down-energy-reserve-StandardBattery-" * string(id) )
        elseif isa(ts, StochasticTimeStruct)
            @constraint(model, [i = 1:ts.periods, j = ts.scenarios], r.state_of_charge[i,j] >= total_up_energy_reserve[i,j], base_name = "up-energy-reserve-StandardBattery-" * string(id) )
            #@constraint(model, r.state_of_charge .>= total_up_energy_reserve, base_name = "up-energy-reserve-SimpleBattery-" * string(id) )
            @constraint(model, [i = 1:ts.periods, j = ts.scenarios], r.capacity - r.state_of_charge[i,j] >= total_down_energy_reserve[i,j], base_name = "down-energy-reserve-StandardBattery-" * string(id) )
        end
    end
    # We have implicitly assumed here that power_out and power_in are not simultaneously
    # non-zero. The program should throw a warning if this occurs and this should be considered
    # a case that the software does not handle or an indication of the possibility of A
    # modelling error.

end

function get_objective_term(b::StandardBattery, ts::IndexedTimeStruct, aggregator::Dict{String, Any})
    throughput_cost = b.throughput_cost
    power_out = sum_out(b, :power, ts)
    power_in = sum_in(b, :power, ts, aggregator)
    total_up_activation = sum_out(b, :up_activation, ts)
    total_down_activation = sum_out(b, :down_activation, ts)
    
    zterm = AffExpr(0)
    zterm = add_to_expression!(zterm, throughput_cost * ( sum(power_out .+ power_in)
                            + sum(total_up_activation .+ total_down_activation) ))
    return -zterm
end