"""
Representing a fixed load/demand that must be met (equality constraint)

"""
function build_aggregatorx_object(t::Type{FixedLoad}, l::Dict{String, Any}, aggregator::Dict{String,Any})
    
    connections = aggregator["Connection"]
    id = l["id"]
    
    source = 0
    for c in connections
        if c.sink == id
            source =  c.source
        end
    end
    
    # Read load data. l["load"] is vector->vector if deterministic, Dict>DenseAbstractArray if stochastic
    load = parse_data(l["load"], aggregator)

    # Empty containers for constraints
    constraint          = Dict{String, Vector{ConstraintRef}}()
    scalar_constraint   = Dict{String, ConstraintRef}()

    return FixedLoad(source, load, constraint, scalar_constraint, id)
end

function set_optimization_variables(model::Model, load::FixedLoad, timestruct::TimeStruct)
    # No variables need
end

function set_optimization_constraints(model::Model, load::FixedLoad, aggregator::Dict{String, Any})
    
    source = get_component(load.source, aggregator)

    base_name = "fixed-load-" * string(load.id) * "-f-" * string(source.id)

    c = set_constraint_equality(model, aggregator["TimeStruct"], source.power[load.id], load.load, base_name)

    load.constraint["energy_conservation"] = c

end