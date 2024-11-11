using Test
using JuMP
using HiGHS
import JSON
optimizer = HiGHS.Optimizer
include("AggregatorX.jl")
using .AggregatorX


@testset begin # Component tests
    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Integer}(undef,0)
    id = 1
    node = StandardNode(power, sources, id)
    @test isa(node, StandardNode)
    @test node.id == 1
end

@testset begin
    println("\n Running function tests...\n")

    # parse_data()
    a = [1,2,3]
    @test a == parse_data(a)
    b = [4,5,6]
    @test a != parse_data(b)
    filepath = joinpath(@__DIR__, "test-systems", "sample-data1.txt")
    data = parse_data(filepath)
    @test typeof(data) <: Vector{<:Number}
    @test size(data) == (3,)

    # Wrong dimensions in input file
    filepath = joinpath(@__DIR__, "test-systems", "sample-data2.txt")
    @test_throws DimensionMismatch parse_data(filepath)

    # JSON file calling data from file
    filepath = joinpath(@__DIR__, "test-systems", "data-from-file.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 9.0 atol = 1e-6

end

@testset begin
    println("\n Running system description tests... \n ")

    # Missing file
    #filepath = joinpath(@__DIR__, "test-systems", "missing-file.json")
    #@test_throws "missing-file.json" buildaggregator(filepath)
    

    # non unique ids

    # missing id
    # Connection entry has an id = 3 that is not in the system list
    filepath = joinpath(@__DIR__, "test-systems", "missing.json")
    @test_throws MissingIdException buildaggregator(filepath)

    # Missing market or resource

    # Connections as array instead of dict with arrays
    # Checks if build returns an array
    filepath = joinpath(@__DIR__, "test-systems", "connection-list.json")
    io = open(filepath, "r");
    sys = JSON.parse(io)
    typetable = build_typetable()
    ids = all_ids(sys)
    @test isa(build_connection(sys["Connection"], typetable, ids), Array)
    end;

@testset begin
    println("\n Running component tests...\n")

    # FCR_N_D1
    # Defintion
    @test hasfield(SimpleCharger, :up_activation)
    @test hasfield(SimpleCharger, :down_activation)
    #Construction
    filepath = joinpath(@__DIR__, "test-systems", "fcr1.json")
    sys,aggregator = buildaggregator(filepath)
    markets = aggregator["Market"]
    fcr_found = false
    for m in markets
        if m.class == "FCR"
            fcr_found = true
        end
    end
    @test fcr_found 
    

    function load_system()
        filepath = joinpath(@__DIR__, "test-systems", "fcr1.json")
        sys,aggregator = buildaggregator(filepath)
        return aggregator
    end
    @test typeof(load_system()) == Dict{String, Any}
    # test activation component in Charger
    up = @test hasfield(SimpleCharger, :up_activation)
    @test hasfield(SimpleCharger, :down_activation)
    aggregator = load_system()
    sc = get_component(1,aggregator)
    if typeof(up) == Test.Pass
        @test typeof(sc.up_activation) == Dict{Integer, Vector{VariableRef}}
        @test typeof(sc.down_activation) == Dict{Integer, Vector{VariableRef}}
    else
        println("skipped tests for simpleCharger")
    end

    # test activation fields in SimpleBattery
    up = @test hasfield(SimpleBattery, :up_activation)
    @test hasfield(SimpleBattery, :down_activation)
    sb = get_component(2,aggregator)
    @test typeof(sb.up_activation) == Dict{Integer, Vector{VariableRef}}
    @test typeof(sb.down_activation) == Dict{Integer, Vector{VariableRef}}

    @test typeof(sc.up_activation[7]) == Vector{VariableRef}
    @test typeof(sc.down_activation[7]) == Vector{VariableRef}

    @test typeof(sb.up_activation[7]) == Vector{VariableRef}
    @test typeof(sb.down_activation[7]) == Vector{VariableRef}

end

@testset begin
    println("\n Running basic optimality tests... \n ")

    # No revenue:
    # A DA market and a simple charger. No market for income so the optimal 
    # solution should be no power flowing and no revenue/costs
    filepath = joinpath(@__DIR__, "test-systems", "no_revenue.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 0.0 atol = 1e-6

    # Max power 1:
    # Sales price is always higher than cost, expect to use max power.
    # Two timesteps. 
    # DA = 1.0, constant.
    # SimpleMarket = 2.0, constant.
    # Max power = 1.0.
    # Expect buy max power 1.0 with revenu 2.0-1.0 = 1.0 per time unit.
    # Total revenue 2.0
    filepath = joinpath(@__DIR__, "test-systems", "max_power.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2.0 atol = 1e-6

    # Max power 2: 
    # Sales price is higher than cost in some timesteps and lower in others. 
    # Expect max power when price is higher and 0 otherwise
    # Max power = 1.0
    # Buy [1.2, 1.6, 2.6, 3.9]
    # Sell [2.4, 1.9, 1.2, 4.6]
    # Expect max power in timesteps 1,2, and 4, 0 in 3, with total revenue
    # 1.2 + 0.3 + 0.7 = 2.2.
    filepath = joinpath(@__DIR__, "test-systems", "max_power2.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2.2 atol = 1e-6

    # Max power 3:
    # As Max power 2 with different max power and costs.
    # Max power = 2.2
    # Buy [1.2, 0, 2.6, 3.9]
    # Sell [4.6, 8.2, 0, 4.6]
    # Expect max power in timesteps 1,2, and 4, 0 in 3, with total revenue
    # (3.4 + 8.2 + 0 + 0.7)*2.2 = 2.2.
    filepath = joinpath(@__DIR__, "test-systems", "max_power3.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 27.06 atol = 1e-6

    # Max storage: 
    # If market price in time unit 2 is higher than timestep 1, and DA price
    # is higher in time unit 2 compared to 1, buy max in timestep 1 and 0 in
    # timestep 2. Discharge battery in timestep 2
    # DA price : [1.5,3], 
    # SimpleMarket price : [1,10]
    # Max storage = 1.0, Max charge/discharge = 1.0
    # Expect revenu equal 8.5 (buy 1.5, sell 10)
    filepath = joinpath(@__DIR__, "test-systems", "battery1.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 8.5 atol = 1e-6
end;

@testset begin

    # Simple FFR market
    # DA price [1,1]
    # Simple market price [1,0.5]
    # FFR price [1,1]
    # First timestep charge battery and charger at full power.
    # -2 buy power, +2 from ffr, +1 from market = +1
    # Second timestep, keep battery, charger full power
    # -1 buy power, +2 from ffr +0.5 market = +1.5
    # FFR capacity given by charger power. Running at max gives 0 + 0.5 revenue
    # from simplemarket and 1 + 1 from FFR market.
    println("\n Running group tests...")
    filepath = joinpath(@__DIR__, "test-systems", "ffr1.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 3.5 atol = 1e-6
end;