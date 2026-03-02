typename = "LimitedConnection"

test1 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test1.json") # For generating model
test2 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test2.json") # Unlimited capacity
test3 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test3.json") # Minimum capacity given load
test4 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test4.json") # Limited capacity
test5 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test5.json") # Balancing markets, low FCR price and no reservation, unlimited capacity
test6 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test6.json") # Balancing markets, high FCR price and maximum reservation , unlimited capacity
test7 = joinpath(@__DIR__, "test-systems", "LimitedConnection-test7.json") # Balancing markets, high FCR price and limited capacity

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

        # Test the optimizaeaggregator returns correct type
        model = optimizeaggregator(aggregator, optimizer)
        @test model isa Model
    end

    @testset verbose=true "$typename optimization" begin
        # test2: large grid connection should not affect optimal operation
        # Battery is maximally used for energy arbitrage.
        sys, aggregator = buildaggregator(test2)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -5.0 atol = 1.0e-6 

        # test3: connection limited to actual load, battery can not be used for arbitrage
        sys, aggregator = buildaggregator(test3)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -6.0 atol = 1.0e-6

        # test4: connection larger then load but limits maximal use of battery for arbitrage
        sys, aggregator = buildaggregator(test4)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -5.5 atol = 1.0e-6

        # test5: Including balacning markets, low price so no reservation, high capacity
        sys, aggregator = buildaggregator(test5)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -5.0 atol = 1.0e-6

         # test6: Including balacning markets, high price, maximum activation
        sys, aggregator = buildaggregator(test6)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -0.5 atol = 1.0e-6

        # test7: Including balacning markets, high price, limited capacity
        sys, aggregator = buildaggregator(test7)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -3.625 atol = 1.0e-6
    end
end