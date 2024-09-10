
# --- Optimization component specific methods ---
# When new AggregatorX components are introduced, new methods for variables and constraints must be set
# These are JuMP specific and should be loaded before and as part of optimizeaggregator() call

# - Variables -

# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, timestruct::TimeStruct) 
    battery.charge = @variable(model, [1:timestruct.periods])
    typestring = lstrip_last_dot(string(typeof(battery)))
    for i in 1:length(battery.charge)
        set_name(battery.charge[i], typestring * string(battery.id) * "_charge_"  * "[" * string(i) * "]" )
    end
    # Maybe a dict which relates each load variable to load object that defined it
end

"""
    set_optimization_variables(model::Model, charger::SimpleCharger, 
    timestruct::TimeStruct)

The available capacity from the charger is given by up/down_capacity[i,g].
For the charger the up_capacity is given by the current load connected to the 
charger, while down_capacity is given by the maximum_power minus the current 
load.
"""
function set_optimization_variables(model::Model, charger::SimpleCharger, 
    timestruct::TimeStruct) 
    # No additional variables needed.

    # available capacity
    # up_capacity = @variable(model, up_capacity[])

end

## For all groups
"""
    set_optimization_variables(model::Model, groups::Set{Group}, timestruct::TimeStruct)

    The group of resources that can participate in a given reserve market needs a variable which represents the total
    up/down regulation capacity the resources can provide, up/down_capacity[g,t], where g is the group and t is the time
    period.

    up_capacity[g,t] is constrained by equality to the sum of what the individual resources in the group provides.
    This is set in the corresponding constraint method. A given market can also set up additional constraints depending
    on the market regulations
"""
function set_optimization_variables(model::Model, groups::Set{Group}, timestruct::TimeStruct)
    up_capacity = @variable(model, up_capacity[groups,1:timestruct.periods])
    down_capacity = @variable(model, down_capacity[groups,1:timestruct.periods])
    return up_capacity, down_capacity
end



## - Constraints -

function set_optimization_constraints(model::Model, charger::SimpleCharger, timestruct::TimeStruct)
    
end

function set_optimization_constraints(model::Model, load::MinAverageLoad, i::Int,  timestruct::TimeStruct)
    N = timestruct.periods
    p_load = model[:p_load]
    @constraint(model, sum(p_load[i,1:N]) >= load.pmin)
end

# Groups

"""
    set_optimization_constraints(model::Model, group::FFRGroup, timestruct::TimeStruct)

    For all groups the up/down_capacity is equal to the sum of capacity provided by all the resources in the group
    and this constrain is set here

    For FFR there is no down regulation so down_capacity is set equal to zero
"""
function set_optimization_constraints(model::Model, group::FFRGroup, timestruct::TimeStruct)
    dc = model[:down_capacity]
    @constraint(model, dc[group,:] == 0)
    # Set upcapacity as sum of all resources
end