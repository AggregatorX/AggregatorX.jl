@testset verbose = true "StandardBattery" begin
    failed = false

    @testset "StandardBattery definition" begin
        t = @test @isdefined(StandardBattery);
        failed = isa(t, Test.Fail) ? true : false
    end

    if !failed
        # Field names
        field_names = fieldnames(StandardBattery)
        @test field_names == (
            :power,
            :sources,
            :state_of_charge,
            :up_capacity,
            :down_capacity,
            :up_activation,
            :down_activation,
            :up_energy_reserve,
            :down_energy_reserve,
            :capacity,
            :initial_charge,
            :max_charge,
            :max_discharge,
            :charging_loss,
            :discharging_loss,
            :throughput_cost,
            :class,
            :id,
        )
    end

    if !failed
        # Field types
        field_types = [fieldtype(StandardBattery, i) for i in 1:length(field_names)]
        @test field_types == [
            Dict{Integer, AbstractArray{VariableRef}},
            Vector{Integer},
            AbstractArray{VariableRef},
            Dict{Integer, AbstractArray{VariableRef}},
            Dict{Integer, AbstractArray{VariableRef}},
            Dict{Integer, AbstractArray{VariableRef}},
            Dict{Integer, AbstractArray{VariableRef}},
            Dict{Integer, AbstractArray{VariableRef}},
            Dict{Integer, AbstractArray{VariableRef}},
            AbstractFloat,
            AbstractFloat,
            AbstractFloat,
            AbstractFloat,
            AbstractFloat,
            AbstractFloat,
            AbstractFloat,
            String,
            Integer
        ]
    end

    # Default constructor
    vi = Vector{Integer}()
    vr = Vector{Real}()
    vvr = Vector{VariableRef}()
    aavr = Vector{VariableRef}()
    d = Dict{Integer, AbstractArray{VariableRef}}()
    f = 1.1
    i = 1
    str = "string"
    standardbattery = StandardBattery(d, vi, aavr, d, d, d, d, d, d, f, f, f, f, f, f, f, str, i)
    @test isa(standardbattery, StandardBattery)

    # AggreagtorX constructor
    filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test1.json")
    @test isa(buildaggregator(filepath)[2], Dict{String, Any})

    @testset verbose = true "StandardBattery optimization setup" begin
        filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test1.json")
        sys, aggregator = buildaggregator(filepath)
        standardbattery = get_component(4, aggregator)
        timestruct = aggregator["TimeStruct"]
        
        model = Model()
        # Test if variable setter exists
        call = try
            set_optimization_variables(model, standardbattery, timestruct)
        catch e
            e
        end
        @test !(call isa MethodError)              
        @test isnothing(call)
        
        # Test initialization of variables
        #filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test1.json")
        #sys, aggregator = buildaggregator(filepath)
        #standardbattery = get_component(4, aggregator)
        #set_optimization_variables(model, standardbattery, timestruct)

        @test variable_by_name(model, "p-StandardBattery-4-2[1]") == standardbattery.power[2][1]

        # Test if constraint setter exists
        call = try
            set_optimization_constraints(model, standardbattery, aggregator)
        catch e
            e
        end
        @test !(call isa MethodError) 
    end

    @testset verbose = true "StandardBattery optimization" begin
        filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test1.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test isa(model, Model)
        @test objective_value(model) ≈ -2 atol=1e-6

        filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test2.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -2.4 atol=1e-6

        filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test3.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -2.72 atol=1e-6

        filepath = joinpath(@__DIR__, "test-systems", "standard-battery-test4.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -2.884 atol=1e-6
    end
end

@testset verbose = true "SimpleBatteryVarParam" begin
    failed = false

    # Check that type is defined
    @testset "SimpleBatteryVarParam definition" begin
        t = @test @isdefined(SimpleBatteryVarParam);
        failed = isa(t, Test.Fail) ? true : false
    end

    # Check appropriate field names
    if !failed
        # Field names
        field_names = fieldnames(SimpleBatteryVarParam)
        @test field_names == (
            :power,
            :sources,
            :state_of_charge,
            :up_capacity,
            :down_capacity,
            :up_activation,
            :down_activation,
            :up_energy_reserve,
            :down_energy_reserve,
            :capacity,
            :initial_charge,
            :max_charge,
            :max_discharge,
            :class,
            :id,
        )
    end

    if !failed
    # Check appropriate field types
    field_types = [fieldtype(SimpleBatteryVarParam, i) for i in 1:length(field_names)]
    @test field_types == [
        Dict{Integer, AbstractArray{VariableRef}},
        Vector{Integer},
        AbstractArray{VariableRef},
        Dict{Integer, AbstractArray{VariableRef}},
        Dict{Integer, AbstractArray{VariableRef}},
        Dict{Integer, AbstractArray{VariableRef}},
        Dict{Integer, AbstractArray{VariableRef}},
        Dict{Integer, AbstractArray{VariableRef}},
        Dict{Integer, AbstractArray{VariableRef}},
        AbstractArray{<:Real},
        AbstractFloat,
        AbstractArray{<:Real},
        AbstractArray{<:Real},
        String,
        Integer
    ]
    end

    # Default constructor
    d = Dict{Integer, Vector{VariableRef}}()
    vi = Vector{Integer}()
    vvr = Vector{VariableRef}()
    vr = Vector{Real}()
    f = 1.1
    str = "string"
    i = 1

    simplebatteryvarparam = SimpleBatteryVarParam(d, vi, vvr, d, d, d, d, d, d, vr, f, vr, vr, str, i)
    @test isa(simplebatteryvarparam, SimpleBatteryVarParam)

    # Access and modification
    simplebatteryvarparam.id = 2
    @test simplebatteryvarparam.id == 2
    
end

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
            Vector{VariableRef},
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
        vvr = Vector{VariableRef}()
        d = Dict{Integer, Vector{VariableRef}}()
        r = 1.1
        i = 1.0
        thermalload = ThermalLoad(va,vr, d, d, d, d, d, d, vvr, r, r, r, vr, r, r, r, vr, i, i)
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
        print(call)
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

    @testset "Thermal load optimization" begin
        # Single timestep
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test-2.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -1 atol=1e-6

        # Two timesteps
        filepath = joinpath(@__DIR__, "test-systems", "thermal-load-test-3.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        @test objective_value(model) ≈ -3 atol=1e-6
    end
end