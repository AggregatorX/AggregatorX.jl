"""
Generic generator component. Power generation is optimization variable. 
Power is assumed second stage variable if StochasticTimeStruct
Constraints only max/min
Objective value with cost
Supports maximum and minimum power, as well as cost for generation.
"""

"Constructor"
function build_aggregatorx_object(gt::Type{Generation}, g::Dict{String, Any}, aggregator::Dict{String,Any})
    
    N           = aggregator["TimeStruct"].periods
    connections = aggregator["Connection"]
    id          = g["id"]

    power = Dict{Integer, Vector{VariableRef}}()
    for c in connections
        if c.source == id
            power[c.sink] = Vector{VariableRef}(undef,N)
        end
    end

    pmax = parse_data(g["pmax"],aggregator)
    pmin = parse_data(g["pmin"],aggregator)

    haskey(g, "cost") ? cost = parse_data(g["cost"], aggregator) : cost = zeros(N)

    return Generation(power, cost, pmax, pmin, id)
end

function set_optimization_variables(model::Model, gen::Generation, timestruct::TimeStruct)
    N = timestruct.periods

    base_name = "p-Generation-" * string(gen.id)

    for k in keys(gen.power)
        gen.power[k] = set_variables_full_set(model, timestruct, base_name)
    end
end

function set_optimization_constraints(model::Model, gen::Generation, aggregator::Dict{String, Any})

    for k in keys(gen.power)
        @constraint(model, gen.power[k] .<= gen.pmax, base_name = "pmax-generation-" * string(gen.id))
        @constraint(model, gen.power[k] .>= gen.pmin, base_name = "pmin-generation-" * string(gen.id))
    end

end

function get_objective_term(g::Generation, ts::IndexedTimeStruct)
    zterm = AffExpr(0)
    for k in keys(g.power)
        zterm = add_to_expression!(zterm, -sum(g.power[k] .* g.cost))
    end
    return zterm
end