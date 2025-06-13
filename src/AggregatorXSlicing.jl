# - Variables - 

function set_variables_full_set(model::Model, ts::IndexedTimeStruct, base_name = "", lower_bound = 0.0)
     return @variable(model, [1:ts.periods], lower_bound = lower_bound, base_name = base_name)
end

function set_variables_full_set(model::Model, ts::StochasticTimeStruct, base_name = "", lower_bound = 0.0)
    x = @variable(model, [1:ts.periods, ts.scenarios], lower_bound = lower_bound, base_name = base_name)
    return x 
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
    @constraint(model, varref[1, ts.scenarios] .== init_val, base_name=base_name)
end

# Temporal evolution
function set_constraint_temporal_evolution(model::Model, ts::IndexedTimeStruct, varref, delta,  base_name = "", lower_bound = 0.0)
    N = ts.periods
    @constraint(model, varref[2:N] == varref[1:N-1] + delta[1:N-1], base_name = base_name )
end

function set_constraint_temporal_evolution(model::Model, ts::StochasticTimeStruct, varref, delta,  base_name = "", lower_bound = 0.0)
    N = ts.periods
    S = ts.scenarios
    @constraint(model, [t=1:N-1, s in S], varref[t+1, s] == varref[t, s] + delta[t, s], base_name = base_name )
end

# Upper bound
function set_constraint_upper_bound(model::Model, ts::TimeStruct, varref, bound, base_name = "")
    @constraint(model, varref .<= bound, base_name = base_name)
end

# ...last time step
function set_constraint_upper_bound_last(model::Model, ts::IndexedTimeStruct, varref, delta, bound, base_name = "")
    N = ts.periods
    @constraint(model, varref[N] + delta[N] <= bound, base_name = base_name)
end

function set_constraint_upper_bound_last(model::Model, ts::StochasticTimeStruct, varref, delta, bound, base_name = "")
    N = ts.periods
    S = ts.scenarios
    @constraint(model, [s = S], varref[N,s] + delta[N,s] <= bound, base_name = base_name)
end

# Lower bound
function set_constraint_lower_bound(model::Model, ts::TimeStruct, varref, bound = 0.0, base_name = "")
    @constraint(model, varref .>= bound, base_name = base_name)
end

# ... last time step
function set_constraint_lower_bound_last(model::Model, ts::IndexedTimeStruct, varref, delta, bound = 0.0, base_name = "")
    N = ts.periods
    @constraint(model, varref[N] + delta[N] >= bound, base_name = base_name)
end
function set_constraint_lower_bound_last(model::Model, ts::StochasticTimeStruct, varref, delta, bound = 0.0, base_name = "")
    N = ts.periods
    S = ts.scenarios
    @constraint(model, [s in S], varref[N,s] + delta[N,s] >= bound, base_name = base_name)
end