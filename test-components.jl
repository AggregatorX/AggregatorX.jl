@testset verbose = true "Thermal load" begin
    failed = false

    @testset "Thermal load defined" begin
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
            Integer
        ]

        # Default constructr
        va = Vector{AffExpr}()
        vr = Vector{Real}()
        d = Dict{Integer, Vector{VariableRef}}()
        r = 1.1
        i = 1.0
        thermalload = ThermalLoad(va,vr, d, d, d, d, d, d, vr, r, r, r, vr, r, r, r, i)
        @test isa(thermalload, ThermalLoad)

        # Access and modification
        thermalload.id = 2
        @test thermalload.id == 2

        # AggregatorX constructor
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        @test isa(buildaggregator(filepath)[2], Dict{String, Any})

        # System spesification missing required key
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test2.json")
        @test_throws IncompleteSystemException buildaggregator(filepath)

        # Test simple system
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        sys, aggregator = buildaggregator(filepath)
        #model = optimizeaggregator(aggregator,optimizer)
        #@test objective_value(model) == -2
    else
        println("Test of definition of thermal load failed, skipping remainin tests")
    end

    @testset "ThermalLoad optimization model" begin
        
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test1.json")
        sys, aggregator = buildaggregator(filepath)
        thermalload = get_component(3, aggregator)
        timestruct = aggregator["TimeStruct"]

        # Setting optimization Variables
        # Check function with signature exists
        exists = try
            set_optimization_variables
        catch e
            e
        end
        @test !isa(exists, UndefVarError)

        model = Model();
        
        if !isa(exists, UndefVarError)
            call = try
                set_optimization_variables(model, thermalload, timestruct)
            catch e
                e
            end
            @test !(call isa MethodError)
        end
    
    end
    # Setting optimization constratints

    # Setting objective function
end