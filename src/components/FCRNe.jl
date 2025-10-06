function set_optimization_variables(model::Model, m::FCRNe, timestruct::TimeStruct)
    N = timestruct.periods

    # - Variables -

    m.capacity_sold = @variable(model, [1:N], lower_bound = 0.0, base_name = "FCRNe-capacity-" * string(m.id))

    # - Intermediate variables -

    # Symmetric market
    m.up_capacity_sold    = @expression(model, [i = 1:N], m.capacity_sold[i]) # Used in objective function
    m.down_capacity_sold  = @expression(model, [i = 1:N], m.capacity_sold[i])
    
    # Variables passed to group
    m.up_capacity    =      @expression(model, [i = 1:N], m.capacity_factor  .* m.up_capacity_sold[i])
    m.down_capacity  =      @expression(model, [i = 1:N], m.capacity_factor  .* m.down_capacity_sold[i])
    m.up_energy_reserve   = @expression(model, [i = 1:N], m.energy_endurance .* m.capacity_sold[i]) # Not needed, pass endurance directly
    m.down_energy_reserve = @expression(model, [i = 1:N], m.energy_endurance .* m.capacity_sold[i]) # -"-
end

function set_optimization_constraints(model::Model, m::FCRNe, aggregator)
    # - no constraints needed-
end

function get_objective_term(m::FCRNe)
    zterm = sum(m.price .* m.capacity_sold .* (-m.sign))
    return zterm
end