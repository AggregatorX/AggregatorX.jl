function set_optimization_variables(model::Model, load::ThermalLoad, timestruct::TimeStruct)
    N = timestruct.periods
    T = 1:N
    varsuffix = "-ThermalLoad-" * string(load.id)

    load.temperature = @variable(model, [T], lower_bound = 0.0, base_name = "temperature" * varsuffix)

    # Initalize AffExpr
    load.power       = init_expr_array(N)

    for k in keys(load.up_capacity) # group key same for all balancing variables
        load.up_capacity[k]        = @variable(model, [T], lower_bound = 0.0, base_name = "up_capacity" * varsuffix)
        load.down_capacity[k]      = @variable(model, [T], lower_bound = 0.0, base_name = "down_capacity" * varsuffix)
        load.up_activation[k]      = @variable(model, [T], lower_bound = 0.0, base_name = "up_activation" * varsuffix)
        load.down_activation[k]    = @variable(model, [T], lower_bound = 0.0, base_name = "down_activation" * varsuffix)
        load.up_energy_reserve[k]  = @variable(model, [T], lower_bound = 0.0, base_name = "up_energy_reserve" * varsuffix)
        load.down_energy_reserve[k]= @variable(model, [T], lower_bound = 0.0, base_name = "down_energy_reserve" * varsuffix)
    end

    # variable for power flowing to this load is set in attached node

    return true
end

function set_optimization_constraints(model::Model, load::ThermalLoad, aggregator::Dict{String, Any})
    # Shorthand
    N     = aggregator["TimeStruct"].periods
    id    = load.id
    T     = load.temperature
    C     = load.heat_capacity
    H     = load.heat_loss_factor
    Ta = load.ambient_temperature
    Pout  = load.load
    aup   = init_expr_array(N)
    adown = init_expr_array(N)

    # Total activation
    for k in keys(load.up_activation)
        aup     = aup + load.up_activation[k]
        adown   = adown + load.down_activation[k]
    end

    # Power inflow
    Pin = load.power = get_component(load.source, aggregator).power[id]

    # Inital value
    c = @constraint(model, T[1] == load.inital_temperature, base_name = "Inital value" )  
    
    # Energy conservation
    c = @constraint(model, [t = 1:N-1], T[t+1] == T[t] + C*(Pin[t] - Pout[t] - aup[t] + adown[t]) - H *(T[t]-Ta[t]), base_name = "Energy conservation" )
    push!(load.constraints, c)

    # Max power
    c = @constraint(model, [t = 1:N], Pin[t] <= load.max_power, base_name = "Max power")
    push!(load.constraints, c)

    # Maximum and minimum temperature
    c1 = @constraint(model, [t = 1:N], T[t] <= load.max_temperature, base_name = "Max T")
    c2 = @constraint(model, [t = 1:N], T[t] >= load.min_temperature, base_name = "Min T")
    push!(load.constraints, c1, c2)

    # Maximum and minimum also at last time step
    c1 = @constraint(model, T[N] + C*(Pin[N] - Pout[N] - aup[N] + adown[N]) - H *(T[N]-Ta[N]) <= load.max_temperature, base_name = "Max T end")
    c2 = @constraint(model, T[N] + C*(Pin[N] - Pout[N] - aup[N] + adown[N]) - H *(T[N]-Ta[N]) >= load.min_temperature, base_name = "Min T end")
    push!(load.constraints, c1,c2)
end