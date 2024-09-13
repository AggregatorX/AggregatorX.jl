
# --- Optimization component specific methods ---
# When new AggregatorX components are introduced, new methods for variables and constraints must be set
# These are JuMP specific and should be loaded before and as part of optimizeaggregator() call

# - Variables -

# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, 
    timestruct::TimeStruct) 
    
    N = timestruct.periods

    for k in keys(battery.power)
        battery.power[k] = @variable(model, [1:N], lower_bound = 0.0,
            base_name = "p-SimpleBattery-" * string(battery.id) * "-" * string(k))
    end
    
    battery.state_of_charge = @variable(model, [1:N], lower_bound = 0.0,
        base_name = "soc-SimpleBattery-" * string(battery.id))
    
    battery.down_capacity = @variable(model, [1:N], lower_bound = 0.0,
        base_name = "down-SimpleBattery-" * string(battery.id))
    
    battery.up_capacity = @variable(model, [1:N], lower_bound = 0.0, 
        base_name = "up-SimpleBattery-" * string(battery.id))

    # typestring = lstrip_last_dot(string(typeof(battery)))
    
    #for i in 1:length(battery.charge)
    #    set_name(battery.charge[i], typestring * string(battery.id) * "_charge_"  * "[" * string(i) * "]" )
    #end

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
        charger.power[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-SimpleCharger-" * string(charger.id) * "-" * string(k))
    end

    charger.up_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-SimpleCharger-" * string(charger.id))
    charger.down_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "down-SimpleCharger-" * string(charger.id))
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
    m.power[m.resource] = @variable(model, [1:N], lower_bound = 0.0, base_name = "SimpleMarket-" * string(m.id))
end

function set_optimization_variables(model::Model, m::SimpleDAMarket, timestruct::TimeStruct)
    N = timestruct.periods
    m.power[m.resource] = @variable(model, [1:N], lower_bound = 0.0, base_name = "SimpleDA-" * string(m.id))
end

function set_optimization_variables(model::Model, m::FFRProfil, timestruct::TimeStruct)
    N = timestruct.periods
    m.up_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-FFRProfil-" * string(m.id))
end



## For all groups
function set_optimization_variables(model::Model, group::FFRGroup, timestruct::TimeStruct)
    group.up_capacity = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "up-FFRgroup-" * string(group.id))
end

"""
    set_optimization_variables(model::Model, groups::Set{Group}, timestruct::TimeStruct)

    The group of resources that can participate in a given reserve market needs a variable which represents the total
    up/down regulation capacity the resources can provide, up/down_capacity[g,t], where g is the group and t is the time
    period.

    up_capacity[g,t] is constrained by equality to the sum of what the individual resources in the group provides.
    This is set in the corresponding constraint method. A given market can also set up additional constraints depending
    on the market regulations
"""
#=
function set_optimization_variables(model::Model, groups::Set{Group}, timestruct::TimeStruct)
    up_capacity = @variable(model, up_capacity[groups,1:timestruct.periods])
    down_capacity = @variable(model, down_capacity[groups,1:timestruct.periods])
    return up_capacity, down_capacity
end
=#

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
        if resource.class == "Load"
            output = output + charger.power[target]
        end
    end
    @constraint(model, charger.up_capacity == output, base_name = "max-up-SimpleCharger-" * string(charger.id) )
    
    # down regulation limited by maximum increase in (external) output = p_max-p_current(ext)
    @constraint(model, charger.down_capacity == charger.max_power .- output, base_name = "max-down-SimpleCharger-" * string(charger.id) )
    
end

function set_optimization_constraints(model::Model, r::SimpleBattery, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods
    id = r.id

    power_out = init_expr_array(N)
    for target in keys(r.power)
        power_out = power_out + r.power[target]
    end 

    power_in = init_expr_array(N) # power_in is positive but for a net flow, a net outflow is defined as positive
    sources = r.sources
    for r in union(aggregator["Resource"], aggregator["Market"])
        if r.id in sources
            power_in = power_in + r.power[id]
        end
    end

    # Energy conserved: Change in state of charge equal net power flow
    net_power = init_expr_array(N)
    net_power = power_out - power_in
    @constraint(model, r.state_of_charge[1] == r.initial_charge)
    @constraint(model,  r.state_of_charge[2:N] - r.state_of_charge[1:N-1] + net_power[1:N-1] == 0, base_name = "soc-SimpleCharger-" * string(id))

    # max charge
    @constraint(model, r.state_of_charge .<= r.max_charge)

    # charge/discharge rates
    @constraint(model, power_out .<= r.max_discharge)
    @constraint(model, power_in .<= r.max_charge)

    # capacity for up/down regulation
    @constraint(model, r.up_capacity == r.max_discharge .- power_out )
    @constraint(model, r.down_capacity == r.max_charge .- power_in )
    # We have implicitly assumed here that power_out and power_in are not simultaneously
    # zero. The program throws a warning if this occurs and this should be considered
    # a case that the software does not handle or an indication of the possibility of A
    # modelling error.
end

#=
function set_optimization_constraints(model::Model, load::MinAverageLoad, i::Int,  timestruct::TimeStruct)
    N = timestruct.periods
    p_load = model[:p_load]
    @constraint(model, sum(p_load[i,1:N]) >= load.pmin)
end
=#

### Markets

function set_optimization_constraints(model::Model, m::SimpleMarket, aggregator)
    source = get_component(m.resource, aggregator)
    @constraint(model, m.power[m.resource] ==  source.power[m.id], base_name = "in-out-SimpleMarket-" * string(m.id))
end

function set_optimization_constraints(model::Model, m::SimpleDAMarket, aggregator)
    
end

function set_optimization_constraints(model::Model, m::FFRProfil, aggregator)
    
end

# Groups

"""
    set_optimization_constraints(model::Model, group::FFRGroup, timestruct::TimeStruct)

    For all groups the up/down_capacity is equal to the sum of capacity provided by all the resources in the group
    and this constrain is set here

    For FFR there is no down regulation so down_capacity is set equal to zero
"""
function set_optimization_constraints(model::Model, group::FFRGroup, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods

    # group capacity is sum of capacity of resources in group
    sum_up_capacity = init_expr_array(N)

    for id in group.resources
        r = get_component(id, aggregator)
        if :up_capacity in fieldnames(typeof(r)) # check if resource can provide up_capacity
            sum_up_capacity = sum_up_capacity + r.up_capacity
        end
    end

    @constraint(model, group.up_capacity == sum_up_capacity, base_name = "up-limit-FFRgroup-" * string(group.id) )

    # capacity sold to markets is limited by available capacity
    sum_sold_capacity = init_expr_array(N)
    for id in group.markets
        m = get_component(id, aggregator)
        sum_sold_capacity = sum_sold_capacity + m.up_capacity
    end
    @constraint(model, group.up_capacity >= sum_sold_capacity,  base_name = "up-sold-FFRGroup-" * string(group.id))
end

# Objective functions contributions

function set_objective(model::Model, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods

    markets = aggregator["Market"]
    
    z = 0
    for m in markets
        zterm = get_objective_term(m)
        z = z + zterm
    end

    return z
end

function get_objective_term(m::SimpleDAMarket)
    zterm = sum(m.power[m.resource] .* m.price .* (-m.sign))
    return zterm
end

function get_objective_term(m::FFRProfil)
    zterm = sum(m.up_capacity .* m.price .* m.armed .* (-m.sign))
    return zterm
end

function get_objective_term(m::SimpleMarket)
    zterm = sum(m.power[m.resource] .* m.price .* (-m.sign))
    return zterm
end