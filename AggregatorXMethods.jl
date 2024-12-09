
# --- Optimization component specific methods ---
# When new AggregatorX components are introduced, new methods for variables and constraints must be set
# These are JuMP specific and should be loaded before and as part of optimizeaggregator() call

# - Variables -

# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, 
    timestruct::TimeStruct) 
    
    N = timestruct.periods

    # Output power
    for k in keys(battery.power)
        battery.power[k] = @variable(model, [1:N], lower_bound = 0.0,
            base_name = "p-SimpleBattery-" * string(battery.id) * "-" * string(k))
    end
    
    # State of charge
    battery.state_of_charge = @variable(model, [1:N], lower_bound = 0.0,
        base_name = "soc-SimpleBattery-" * string(battery.id))
    
    # Capacity    
    for k in keys(battery.up_capacity)
        battery.up_capacity[k] = @variable(model, [1:N], lower_bound = 0.0, 
            base_name = "up-capacity-SimpleBattery-" * string(battery.id) * "-group-" * string(k))
    end

    for k in keys(battery.down_capacity)
        battery.down_capacity[k] = @variable(model, [1:N], lower_bound = 0.0, 
        base_name = "down-capacity-SimpleBattery-" * string(battery.id) * "-group-" * string(k))
    end

    # Activation
    for k in keys(battery.up_activation)
        battery.up_activation[k] = @variable(model, [1:N], lower_bound = 0.0,
        base_name = "up-activation-SimpleBattery-" * string(battery.id) * "-group-" * string(k))
    end

    for k in keys(battery.down_activation)
        battery.down_activation[k] = @variable(model, [1:N], lower_bound = 0.0,
        base_name = "down-activation-SimpleBattery-" * string(battery.id) * "-group-" * string(k))
    end
    
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

    #charger.up_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-SimpleCharger-" * string(charger.id))
    #charger.down_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "down-SimpleCharger-" * string(charger.id))

    # Capacity
    for k in keys(charger.up_capacity)
        charger.up_capacity[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-capactity-SimpleCharger-" * string(charger.id) * "-g-" * string(k))
    end

    for k in keys(charger.down_capacity)
        charger.down_capacity[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-capacity-SimpleChareger-" * string(charger.id) * "-g-" * string(k))
    end

    # Activation
    for k in keys(charger.up_activation)
        charger.up_activation[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-activation-SimpleChareger-" * string(charger.id))
    end

    for k in keys(charger.down_activation)
        charger.down_activation[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "down-activation-SimpleCharger-" * string(charger.id))
    end
end

function set_optimization_variables(model::Model, load::FixedLoad, timestruct::TimeStruct)
    # No variables need
end

function set_optimization_variables(model::Model, load::VariableLoad, timestruct::TimeStruct)
    N = timestruct.periods

    for k in keys(load.power)
        load.power[k] = @variable(model, [1:N], base_name = "power-VariableLoad-" * string(load.id))
    end
    
end

# These are used for each load if there are additional variables to be defined depending on type
function set_optimization_variables(model::Model, load::MinAverageLoad, timestruct::TimeStruct) 
    # return charge, charging, discharging
    @variable(model, p_load[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

function set_optimization_variables(model::Model, load::MinLoad, timestruct::TimeStruct)
    # No variables needed
end

## Grids
function set_optimization_variables(model, g::LinearTariff, timestruct::TimeStruct)
    N = timestruct.periods
    for k in keys(g.power)
        g.power[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-Grid-" * string(g.id))
    end
end

## Markets

function set_optimization_variables(model::Model, m::SimpleMarket, timestruct::TimeStruct)
    N = timestruct.periods
    m.power[m.resource] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-SimpleMarket-" * string(m.id))
end

function set_optimization_variables(model::Model, m::SimpleDAMarket, timestruct::TimeStruct)
    N = timestruct.periods
    m.power[m.resource] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-SimpleDA-" * string(m.id))
end

function set_optimization_variables(model::Model, m::FFRProfil, timestruct::TimeStruct)
    N = timestruct.periods
    m.up_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "up-capacity-FFRProfil-" * string(m.id))
end

function set_optimization_variables(model::Model, m::FCRN, timestruct::TimeStruct)
    N = timestruct.periods
    m.up_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "FCRN-up-capacity-" * string(m.id))
    m.down_capacity = @variable(model, [1:N], lower_bound = 0.0, base_name = "FCRN-down-capacity-" * string(m.id))
    m.up_activation = @variable(model, [1:N], lower_bound = 0.0, base_name = "FCRN-up-activation-" * string(m.id))
    m.down_activation = @variable(model, [1:N], lower_bound = 0.0, base_name = "FCRN-down-activation-" * string(m.id))
end

## Nodes
function set_optimization_variables(model::Model, node::StandardNode, timestruct::TimeStruct)
    N = timestruct.periods
    for k in keys(node.power)
        node.power[k] = @variable(model, [1:N], lower_bound = 0.0, base_name = "p-StandardNode-" * string(node.id) * "-" * string(k))
    end
end

## Groups
function set_optimization_variables(model::Model, group::FFRGroup, timestruct::TimeStruct)
    #group.up_capacity = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "up-FFRgroup-" * string(group.id))
end

function set_optimization_variables(model::Model, group::FCRGroup, timestruct::TimeStruct)
    #group.up_capacity = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "FCRgroup-up-capacity-" * string(group.id))
    #group.down_capacity = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "FCRgroup-down-capacity-" * string(group.id))
    #group.up_activation = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "FCRgroup-up-activation-" * string(group.id))
    #group.down_activation = @variable(model, [1:timestruct.periods], lower_bound = 0.0, base_name = "FCRgroup-down-activation-" * string(group.id))
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
    power_out = init_expr_array(N)
    net_power = init_expr_array(N)
    for target in keys(charger.power)
        #net_power = net_power + charger.power[target]
        power_out = power_out + charger.power[target]
    end 
    #net_power = power_out
    power_in = init_expr_array(N)
    for r in all_components(aggregator) #union(aggregator["Resource"], aggregator["Market"]) and nodes
        if r.id in charger.sources
            #net_power = net_power - r.power[id]
            power_in = power_in + r.power[id]
        end
    end
    net_power = power_out-power_in

    # Planned consumption must be balanced
    @constraint(model, net_power == 0, base_name = "pnet-SimpleCharger-" * string(id))

    total_up_activation = init_expr_array(N)
    total_down_activation = init_expr_array(N)
    for k in keys(charger.up_activation)
        total_up_activation = total_up_activation + charger.up_activation[k]
    end
    for k in keys(charger.down_activation)
        total_down_activation = total_down_activation + charger.down_activation[k]
    end
    #net_activation = total_up_activation - total_down_activation

    # Maximum power and down activation limit
    @constraint(model, total_down_activation .<= charger.max_power .- power_out, base_name = "pmax-SimpleCharger-" * string(id))

    # Non-negative power and up activation limit
    @constraint(model,  total_up_activation .<= power_out, base_name = "pmin-SimpleCharger-" * string(id))

    total_up_capacity = init_expr_array(N)
    total_down_capacity = init_expr_array(N)
    for k in keys(charger.up_capacity)
        total_up_capacity = total_up_capacity + charger.up_capacity[k]
    end
    for k in keys(charger.down_capacity)
        total_down_capacity = total_down_capacity + charger.down_capacity[k]
    end
    # down regulation limited by maximum possible increase in output
    if !(isempty(charger.up_capacity))
        @constraint(model, total_down_capacity == charger.max_power .- power_out, base_name = "max-down-capacity-SimpleCharger-" * string(charger.id) )
    end
    # Up regulation capacity limited by current power flow that can be curtailed.
    if !(isempty(charger.up_capacity))
        @constraint(model, total_up_capacity == power_out, base_name = "max-up-capacity-SimpleCharger-" * string(charger.id) )
    end
    # Should perhaps have a connection between direct linkt between available capacity and maximum acitvation
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
    for r in all_components(aggregator) #union(aggregator["Resource"], aggregator["Market"])
        if r.id in sources
            power_in = power_in + r.power[id]
        end
    end

    net_power = init_expr_array(N)
    net_power = power_out - power_in

    total_up_activation = init_expr_array(N)
    for k in keys(r.up_activation)
        total_up_activation = total_up_activation + r.up_activation[k]
    end

    total_down_activation = init_expr_array(N)
    for k in keys(r.down_activation)
        total_down_activation = total_down_activation + r.down_activation[k]
    end

    net_activation = init_expr_array(N)
    net_activation = total_up_activation - total_down_activation # Positive for net power out, that is up-regulation

    # Energy conserved: Change in state of charge equal net power flow
    @constraint(model, r.state_of_charge[1] == r.initial_charge, base_name = "soc-init-SimpleBattery" * string(id))
    @constraint(model, r.state_of_charge[2:N] - r.state_of_charge[1:N-1] + net_power[1:N-1] + net_activation[1:N-1] == 0, base_name = "soc-SimpleBattery-" * string(id))
    
    # max charge
    @constraint(model, r.state_of_charge .<= r.capacity, base_name ="max-soc-SimpleBattery" * string(id))
    @constraint(model, r.state_of_charge[N] - net_power[N] - net_activation[N] <= r.capacity, base_name ="max-soc_last-SimpleBattery" * string(id)) # last time step

    # min charge
    @constraint(model, r.state_of_charge .>= 0.0, base_name ="min-soc-SimpleBattery" * string(id))
    @constraint(model, r.state_of_charge[N] - net_power[N] - net_activation[N] >= 0.0, base_name ="min-soc-last-SimpleBattery" * string(id)) # last time step

    # charge/discharge rates
    @constraint(model, power_out + total_up_activation .<= r.max_discharge, base_name ="max-discharging-SimpleBattery" * string(id))
    @constraint(model, power_in + total_down_activation .<= r.max_charge, base_name ="max-charging-SimpleBattery" * string(id))

    total_up_capacity = init_expr_array(N)
    for k in keys(r.up_capacity)
        total_up_capacity = total_up_capacity + r.up_capacity[k]
    end

    total_down_capacity = init_expr_array(N)
    for k in keys(r.down_capacity)
        total_down_capacity = total_down_capacity + r.down_capacity[k]
    end

    # Capacity for up/down regulation. Flow constrained
    if !(isempty(r.up_capacity))
        @constraint(model, total_up_capacity <= r.max_discharge .- power_out .+ power_in, base_name="max-up-capacity-SimpleBattery-" * string(id))
    end
    if !(isempty(r.down_capacity))
        @constraint(model, total_down_capacity <= r.max_charge .- power_in .+ power_out, base_name="max-down-capacity-SimpleBattery-" * string(id) )
    end

    # Capacity for up/down regulation. SoC constrained
    if ( !(isempty(r.up_capacity)) & !(isempty(r.down_capacity)) )
        @constraint(model, r.state_of_charge - net_power + total_down_capacity .<= r.capacity, base_name ="capacity-max-soc-SimpleBattery-" * string(id))
        @constraint(model, r.state_of_charge - net_power - total_up_capacity .>= 0.0, base_name ="capacity-min-soc-SimpleBattery-" * string(id))
    end

    # We have implicitly assumed here that power_out and power_in are not simultaneously
    # non-zero. The program should throw a warning if this occurs and this should be considered
    # a case that the software does not handle or an indication of the possibility of A
    # modelling error.
end

function set_optimization_constraints(model::Model, l::FixedLoad, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods
    source = get_component(l.source, aggregator)
    @constraint(model, source.power[l.id][1:N] == l.load[1:N], base_name = "fixed-load-" * string(l.id) * "-f-" * string(source.id))
end

function set_optimization_constraints(model::Model, l::VariableLoad, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods
    len = length(l.sources)
    
    if len == 1        
        source = get_component(l.sources[1], aggregator)
    elseif len != 1
        # throw error, mulitple (or zero) inputs, currently not supported
    end
    
    @constraint(model, source.power[l.id][1:N] >= l.lower_bound[1:N], base_name = "lower-bound-variable-load-" * string(l.id))
    @constraint(model, source.power[l.id][1:N] <= l.upper_bound[1:N], base_name = "upper-bound-variable-load-" * string(l.id))

    for k = keys(l.power)
        @constraint(model, l.power[k[1]][1:N] == source.power[l.id][1:N], base_name = "in-out-variable-load-" * string(l.id))
    end
end

function set_optimization_constraints(model::Model, l::MinLoad, aggregator::Dict{String, Any})
    source = get_component(l.source, aggregator)
    @constraint(model, source.power[l.id] .>= l.pmin, base_name = "MinLoad-" * string(l.id))
end

#=
function set_optimization_constraints(model::Model, load::MinAverageLoad, i::Int,  timestruct::TimeStruct)
    N = timestruct.periods
    p_load = model[:p_load]
    @constraint(model, sum(p_load[i,1:N]) >= load.pmin)
end
=#

### Grids

function set_optimization_constraints(model::Model, g::LinearTariff, aggregator::Dict{String, Any})
    source = get_component(g.sources[1], aggregator)
    target = collect(keys(g.power))[1]
    
    @constraint(model, g.power[target] == source.power[g.id], base_name = "pnet-LinearTariff" * string(g.id))

    @constraint(model, g.power[target] <= g.upper_bound, base_name = "pmax-LinearTariff" * string(g.id))
end

### Markets

function set_optimization_constraints(model::Model, m::SimpleMarket, aggregator)
    if m.sign == -1 # market is a sink
        source = get_component(m.resource, aggregator)
        @constraint(model, m.power[m.resource] ==  source.power[m.id], base_name = "pnet-SimpleMarket-" * string(m.id))
    end
end

function set_optimization_constraints(model::Model, m::SimpleDAMarket, aggregator)
    if m.sign == -1 # market is a sink
        source = get_component(m.resource, aggregator)
        @constraint(model, m.power[m.resource] ==  source.power[m.id], base_name = "pnet-SimpleMarket-" * string(m.id))
    end
end

function set_optimization_constraints(model::Model, m::FFRProfil, aggregator)
    # Minimum bid
    # capacity same for all time steps
end

function set_optimization_constraints(model::Model, m::FCRN, aggregator)
    
    # Symmetric market
    @constraint(model, m.up_capacity .== m.down_capacity, base_name = "fcrn-symmetric-" * string(m.id))

    df = m.df
    dfmax = m.dfmax

    df_up = copy(m.df)
    df_up[df_up .> 0 ] .= 0
    df_up[df_up .< -dfmax] .= 0
    
    df_down = copy(m.df)
    df_down[df_down .< 0 ] .= 0
    df_up[df_down .> dfmax] .= 0

    # Link activation to sold capacity and frequency deviation
    @constraint(model, m.up_activation .== m.up_capacity .* df_up ./ dfmax )
    @constraint(model, m.down_activation .== m.down_capacity .* df_down ./ dfmax )

end

## Nodes
function set_optimization_constraints(model::Model, node::StandardNode, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods
    id = node.id

    power_out = init_expr_array(N)
    net_power = init_expr_array(N)
    power_in = init_expr_array(N)

    for target in keys(node.power)        
        power_out = power_out + node.power[target]
    end 
        
    for r in all_components(aggregator) # Resources, markets, nodes, grids
        if r.id in node.sources
            power_in = power_in + r.power[id]
        end
    end

    net_power = power_out-power_in # Energy conserved
    
    @constraint(model, net_power == 0, base_name = "pnet-Standardode-" * string(id))
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
    total_up_capacity = init_expr_array(N)
    for id in group.resources
        r = get_component(id, aggregator)
        if :up_capacity in fieldnames(typeof(r)) # check if resource can provide up_capacity            
            total_up_capacity = total_up_capacity + r.up_capacity[group.id]
        end
    end

    group.up_capacity = total_up_capacity
    #@constraint(model, group.up_capacity == total_up_capacity, base_name = "up-limit-FFRgroup-" * string(group.id) )

    # capacity sold to markets is limited by available capacity
    sum_sold_capacity = init_expr_array(N)
    for id in group.markets
        m = get_component(id, aggregator)
        sum_sold_capacity = sum_sold_capacity + m.up_capacity
    end
    @constraint(model, group.up_capacity >= sum_sold_capacity,  base_name = "up-sold-FFRGroup-" * string(group.id))

    # Activation 

    # FFR markets have no activation component so this just ensures that the resources
    # does not contribute activation to this group
    for id in group.resources
        r = get_component(id,aggregator)
        @constraint(model, r.up_activation[group.id] == 0, base_name = "no-activation-FFRGroup" * string(group.id))
        @constraint(model, r.down_activation[group.id] == 0, base_name = "no-activation-FFRGroup" * string(group.id))
    end
    

end

function set_optimization_constraints(model::Model, group::FCRGroup, aggregator::Dict{String, Any})
    N = aggregator["TimeStruct"].periods

    # Reserved power/capacity 

    # Group capacity is is capacity of sum of capacity of individual resources
    total_up_capacity_available = init_expr_array(N)
    total_down_capacity_available = init_expr_array(N)

    for id in group.resources
        r = get_component(id, aggregator)
        total_up_capacity_available = total_up_capacity_available + r.up_capacity[group.id]
        total_down_capacity_available = total_down_capacity_available + r.down_capacity[group.id]
    end

    group.up_capacity = total_up_capacity_available
    group.down_capacity = total_down_capacity_available

    # Capacity sold to markets is limited by available capacity
    total_up_capacity_reserved = init_expr_array(N)
    total_down_capacity_reserved = init_expr_array(N)

    for id in group.markets
        m = get_component(id, aggregator)
        total_up_capacity_reserved = total_up_capacity_reserved + m.up_capacity
        total_down_capacity_reserved = total_down_capacity_reserved + m.down_capacity
    end

    @constraint(model, total_up_capacity_reserved <= group.up_capacity, base_name = "up-capacity-limit-FCRGrup" * string(group.id))
    @constraint(model, total_down_capacity_reserved <= group.down_capacity, base_name = "down-capacity-limit-FCRGrup" * string(group.id))

    # Activation

    # Total activated power in the resources
    total_up_activation_resource = init_expr_array(N)
    total_down_activation_resource = init_expr_array(N)
    for id in group.resources
        r = get_component(id,aggregator)
        total_up_activation_resource = total_up_activation_resource + r.up_activation[group.id]
        total_down_activation_resource = total_down_activation_resource + r.down_activation[group.id]
    end
    group.up_activation = total_up_activation_resource
    group.down_activation = total_down_activation_resource

    # Total activated power sold in markets
    total_up_activation_markets = init_expr_array(N)
    total_down_activation_markets = init_expr_array(N)
    for id in group.markets
        m = get_component(id,aggregator)
        total_up_activation_markets = total_up_activation_markets + m.up_activation
        total_down_activation_markets = total_down_activation_markets + m.down_activation
    end

    # Constrained to be equal
    @constraint(model,total_up_activation_markets == total_up_activation_resource, base_name = "up-activation-balance-FCRGroup" * string(group.id))
    @constraint(model,total_down_activation_markets == total_down_activation_resource, base_name = "down-activation-balance-FCRGroup" * string(group.id))

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

    # Grid tariff
    if haskey(aggregator,"Grid")
        for g in aggregator["Grid"]
            zterm = get_objective_term(g)
            z = z + zterm
        end
    end

    return z
end

function get_objective_term(m::SimpleMarket)
    zterm = sum(m.power[m.resource] .* m.price .* (-m.sign))
    return zterm
end

function get_objective_term(m::SimpleDAMarket)
    zterm = sum(m.power[m.resource] .* m.price .* (-m.sign))
    return zterm
end

function get_objective_term(m::FFRProfil)
    zterm = sum(m.up_capacity .* m.price .* m.armed .* (-m.sign))
    return zterm
end

function get_objective_term(m::FCRN)
    capacity = sum(m.up_capacity .* m.price_capacity .* (-m.sign))
    up_activation = sum(m.up_activation .* m.price_up_activation .* (-m.sign))
    down_activation = sum(m.down_activation .* m.price_down_activation .* (-m.sign))
    zterm = capacity + up_activation - down_activation
    return zterm
end

function get_objective_term(g::LinearTariff)
    target = collect(keys(g.power))[1]
    zterm = sum(-g.price .* g.power[target])
end