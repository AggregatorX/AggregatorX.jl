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
