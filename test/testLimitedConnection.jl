typename = "LimitedConnection"

test1 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test1.json")

@testset verbose=true "$typename" begin

    defined = false
    @testset verbose=true "$typename definition" begin
        result = @test isdefined(AggregatorX, :LimitedConnection)
        defined = isa(result, Test.Fail) ? false : true

        if defined
            names = fieldnames(LimitedConnection)
            @test names == (
                :power,
                :sources,
                :upper_bound,
                :capacity_markets,
                :activation_markets,
                :id
            )
        end

        if defined
            types = [fieldtype(LimitedConnection, name) for name in names]
            @test types == [
                Dict{Integer, Vector{VariableRef}},
                Vector{Integer},
                Vector{Real},
                Vector{Integer},
                Vector{Integer},
                Integer
            ]
        end
    end

    @testset verbose=true "$typename constructors" begin
        vi = Vector{Integer}()
        vr = Vector{Real}()
        d = Dict{Integer, Vector{VariableRef}}()
        i = 1
        args = (d, vi, vr, vi, vi, i)
        @test isa(LimitedConnection(args...), LimitedConnection)

        # Minimum aggregator object
        aggregator = Dict{String, Any}()
        typetable = AggregatorX.build_typetable()
        io = open(test1, "r") # TODO: add more complex systems with balancing markets
        sys = JSON.parse(io)
        ids = all_ids(sys)
        aggregator["TimeStruct"] = AggregatorX.build_aggregatorx_object(IndexedTimeStruct, sys["TimeStruct"])
        aggregator["Connection"] = AggregatorX.build_connection(sys["Connection"], typetable, ids)
        
        # AggregatorX constructor wrapper
        @test isa(build_aggregatorx_object(LimitedConnection, sys["Grid"][1], aggregator), LimitedConnection)

        # Test full build
        @test isa(buildaggregator(test1)[2], Dict{String, Any})
    end

    @testset verbose=true "$typename optimization setup" begin
        # build system        
        sys, aggregator = buildaggregator(test1)
        limitedconnection = get_component(2, aggregator)
        timestruct = aggregator["TimeStruct"]
        model = Model()
        
        # Test if variable setter exists
        @test applicable(set_optimization_variables, model, limitedconnection, timestruct)

        # Test if constraint setter exists 
        @test applicable(set_optimization_constraints,model, limitedconnection, aggregator)
    end
end