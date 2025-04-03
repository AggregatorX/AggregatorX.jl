@testset verbose = true "ThermalLoad" begin
    failed = false

    @testset "ThermalLoad definition" begin
        t = @test @isdefined(ThermalLoad);
        failed = isa(t,Test.Fail) ? true : false
    end

    if !failed
        # Field names
        field_names = fieldnames(ThermalLoad)
        @test field_names == (
            :power,
            :load,
            :up_capacity,
            :down_capacity,
            :up_activation,
            :down_activation,
            :up_energy_reserve,
            :down_energy_reserve,
            :temperature,
            :inital_temperature,
            :max_temperature,
            :min_temperature,
            :ambient_temperature,
            :heat_capacity,
            :heat_loss_factor,
            :max_power,
            :constraints,
            :source,
            :id
        )

        # Field types
        field_types = [fieldtype(ThermalLoad, i) for i in 1:length(field_names)]
        @test field_types == [
            Vector{AffExpr},
            Vector{Real},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Vector{AffExpr},
            Real,
            Real,
            Real,
            Vector{Real},
            Real,
            Real,
            Real,
            Vector{Any},
            Integer,
            Integer
        ]

        # Default constructr
        va = Vector{AffExpr}()
        vr = Vector{Real}()
        d = Dict{Integer, Vector{VariableRef}}()
        r = 1.1
        i = 1.0
        thermalload = ThermalLoad(va,vr, d, d, d, d, d, d, vr, r, r, r, vr, r, r, r, vr, i, i)
        @test isa(thermalload, ThermalLoad)

        # Access and modification
        thermalload.id = 2
        @test thermalload.id == 2

        # AggregatorX constructor
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        @test isa(buildaggregator(filepath)[2], Dict{String, Any})

        # System spesification missing required key
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test-missing.json")
        @test_throws IncompleteSystemException buildaggregator(filepath)

        # Test simple system
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        sys, aggregator = buildaggregator(filepath)
        #model = optimizeaggregator(aggregator,optimizer)
        #@test objective_value(model) == -2
    else
        println("Test of definition of thermal load failed, skipping remainin tests")
    end

    @testset "ThermalLoad optimization setup" begin
        
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        sys, aggregator = buildaggregator(filepath)
        thermalload = get_component(3, aggregator)
        timestruct = aggregator["TimeStruct"]
        
        model = Model()
        # Test if variable setter exists
        call = try
            set_optimization_variables(model, thermalload, timestruct)
        catch e
            e
        end
        @test !(call isa MethodError)              
        @test call

        # Test initialization of variables
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test-group.json")
        sys, aggregator = buildaggregator(filepath)
        thermalload = get_component(3, aggregator)
        set_optimization_variables(model, thermalload, timestruct)

        @test variable_by_name(model, "up_capacity-ThermalLoad-3[1]") == thermalload.up_capacity[4][1]
        @test thermalload.power[1] == 0.0

        # Test if constraint setter exists
        call = try
            set_optimization_constraints(model, thermalload, aggregator)
        catch e
            e
        end
        @test !(call isa MethodError) 
        
    end
    # Setting optimization constratints

    # Setting objective function
end