
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

# SimpleCharger
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
    N = timestruct.periods

    for k in keys(charger.power)
        charger.power[k] = @variable(model, [1:N], base_name = "p-SimpleCharger-" * string(charger.id) * "-" * string(k))
    end

    charger.up_capacity = @variable(model, [1:N], base_name = "up-SimpleCharger-" * string(charger.id))
    charger.down_capacity = @variable(model, [1:N], base_name = "down-SimpleCharger-" * string(charger.id))
end

# These are used for each load if there are additional variables to be defined depending on type
function set_optimization_variables(model::Model, load::MinAverageLoad, timestruct::TimeStruct) 
    # return charge, charging, discharging
    @variable(model, p_load[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

## Markets

function set_optimization_variables(model::Model, m::SimpleMarket, timestruct::TimeStruct)
    N = timestruct.periods
    m.power[m.resource] = @variable(model, [1:N], base_name = "SimpleMarket-" * string(m.id))
end

function set_optimization_variables(model::Model, m::SimpleDAMarket, timestruct::TimeStruct)
    N = timestruct.periods
    m.power[m.resource] = @variable(model, [1:N], base_name = "SimpleDA-" * string(m.id))
end

function set_optimization_variables(model::Model, m::FFRProfil, timestruct::TimeStruct)
    N = timestruct.periods
    m.capacity = @variable(model, [1:N], base_name = "FFRProfil-" * string(m.id))
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

function set_optimization_constraints(model::Model, charger::SimpleCharger, aggregator)
    N = aggregator["TimeStruct"].periods
    id = charger.id

    # Energy conserved
    net_power = init_expr_array(N)
    for target in keys(charger.power)
        net_power = net_power + charger.power[target]
    end 
    sources = charger.sources
    for r in union(aggregator["Resource"], aggregator["Market"])
        if r.id in sources
            net_power = net_power - r.power[id]
        end
    end

    @constraint(model, net_power == 0, base_name = "pnet-SimpleCharger-" * string(id))

    # up regulation limited by curtailable (eksternal) power
    output = init_expr_array(N) 
    for target in keys(charger.power) 
        resource = get_component(target, aggregator)
        println(target)
        println(resource)
        if resource.class == "Load"
            output = output + charger.power[target]
        end
    end
    @constraint(model, charger.down_capacity <= output, base_name = "max-down-SimpleCharger-" * string(charger.id) )
    
    
    # down regulation limited by maximum increase in (external) output
    
end

function set_optimization_constraints(model::Model, load::MinAverageLoad, i::Int,  timestruct::TimeStruct)
    N = timestruct.periods
    p_load = model[:p_load]
    @constraint(model, sum(p_load[i,1:N]) >= load.pmin)
end

### Markets

function set_optimization_constraints(model::Model, m::SimpleMarket, aggregator)
    source = get_component(m.resource, aggregator)
    @constraint(model, m.power[m.resource] ==  source.power[m.id], base_name = "in-out-SimpleMarket-" * string(m.id))
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

# Objective

function get_objective_term(m::SimpleDAMarket)
    zterm = sum(m.power[m.resource] .* m.price)
    return zterm
end

# Objective function for ffr