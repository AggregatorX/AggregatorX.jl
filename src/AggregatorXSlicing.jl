# - Variables - 

function set_variables_full_set(model::Model, ts::IndexedTimeStruct, base_name = "", lower_bound = 0.0)
     return @variable(model, [1:ts.periods], lower_bound = lower_bound, base_name = base_name)
end

function set_variables_full_set(model::Model, ts::StochasticTimeStruct, base_name = "", lower_bound = 0.0)
     return @variable(model, [1:ts.periods, ts.scenarios], lower_bound = lower_bound, base_name = base_name)
end

# Called for both indexed and stochastic time struct
function set_variables_first_stage(model::Model, ts::TimeStruct, base_name = "", lower_bound = 0.0)
    return @variable(model, [1:ts.periods], lower_bound = lower_bound, base_name = base_name)
end

# - Constraints -

# Inital value
function set_constraint_initial_value(model::Model, ts::IndexedTimeStruct, varref, init_val,  base_name = "", lower_bound = 0.0)
    @constraint(model, varref[1] == init_val, base_name=base_name)
end

function set_constraint_initial_value(model::Model, ts::StochasticTimeStruct, varref, init_val, base_name = "", lower_bound = 0.0)
    @constraint(model, varref[1, ts.scenarios] == init_val, base_name=base_name)
end

# Temporal evolution
function set_constraint_temporal_evolution(model::Model, ts::IndexedTimeStruct, varref, delta,  base_name = "", lower_bound = 0.0)
    N = ts.periods
    @constraint(model, varref[2:N] == varref[1:N-1] + delta[1:N-1] )
end

# Temporal evolution
function set_constraint_temporal_evolution(model::Model, ts::StochasticTimeStruct, varref, delta,  base_name = "", lower_bound = 0.0)
    N = ts.periods
    S = ts.scenarios
    @constraint(model, varref[2:N, S] == varref[1:N-1, S] + delta[1:N-1, S] )
end