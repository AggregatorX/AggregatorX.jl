using Test
using JuMP
using HiGHS
import JSON
optimizer = HiGHS.Optimizer

loaded = false
for n in names(Main)    
    if n == :AggregatorX
        global loaded = true
    end
end

# Load AggregatorX
if !loaded # Errors occur if module is loaded multiple times
    include("AggregatorX.jl")
    using .AggregatorX
end

using .AggregatorX

println("\n Running component tests... \n ")

@testset begin # Component tests
    power = Dict{Integer, Vector{VariableRef}}()
    sources = Vector{Integer}(undef,0)
    id = 1
    node = StandardNode(power, sources, id)
    @test isa(node, StandardNode)
    @test node.id == 1

    @test hasfield(SimpleBattery, :up_energy_reserve)
    @test hasfield(SimpleBattery, :down_energy_reserve)

    @test hasfield(FCReGroup, :up_energy_reserve)
    @test hasfield(FCReGroup, :down_energy_reserve)

    # FCRe
    @test hasfield(FCRNe, :capacity_sold)
    @test hasfield(FCRNe, :up_capacity_sold)
    @test hasfield(FCRNe, :up_energy_reserve)
end

@testset begin
    println("\n Running function tests...\n")

    # Testing parse_data function

    # Vector input
    a = [1,2,3]
    @test a == parse_data(a)
    b = [4,5,6]
    @test a != parse_data(b)
    
    # Input as a filename string
    filepath = joinpath(@__DIR__, "test-systems", "sample-data1.txt")
    data = parse_data(filepath)
    @test typeof(data) <: Vector{<:Number}
    @test size(data) == (3,)
    @test data ≈ [1.0, 2.0, 3.0] atol = 1e-6/length(data)

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
    

    # FCReGroup
    filepath = joinpath(@__DIR__, "test-systems", "fcre1.json")
    sys,aggregator = buildaggregator(filepath)
    groups = aggregator["Group"]
    for g in groups
        @test typeof(g) == FCReGroup
        @test typeof(g.up_capacity) == Vector{AffExpr}
        @test typeof(g.up_energy_reserve) == Vector{AffExpr}
        @test typeof(g.resources) == Set{Int}
    end
    # Optimization
    model = optimizeaggregator(aggregator, optimizer)
    group = get_component(4, aggregator)
    @test hasfield(typeof(group), :up_energy_reserve)
    @test typeof(group.up_energy_reserve) == Vector{AffExpr}

    # FCRN - market
    # Defintion
    @test hasfield(FCRN, :up_activation)
    @test hasfield(FCRN, :down_activation)
    @test hasfield(FCRN, :up_capacity)
    @test hasfield(FCRN, :down_capacity)
    #Construction
    filepath = joinpath(@__DIR__, "test-systems", "fcr1.json")
    sys,aggregator = buildaggregator(filepath)
    markets = aggregator["Market"]
    fcr_found = false
    fcrmarket = nothing
    for m in markets
        if m.class == "FCR"
            fcr_found = true
            fcrmarket = m
        end
    end
    @test fcr_found

    @test typeof(fcrmarket.up_activation) == Vector{VariableRef}
    @test typeof(fcrmarket.up_capacity) == Vector{VariableRef}
    

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

    # Fixed Load
    @test begin
        load = [1,2,3]
        id = 1
        source = 2
        fixedload = FixedLoad(source, load, id)
        isa(fixedload, FixedLoad)
    end
    @test begin
        filepath = joinpath(@__DIR__, "test-systems", "fixed_load_test.json")
        sys,aggregator = buildaggregator(filepath)
        resources = aggregator["Resource"]
        isa(resources[1], FixedLoad)
    end
    filepath = joinpath(@__DIR__, "test-systems", "fixed_load_test.json")
    sys,aggregator = buildaggregator(filepath)
    fixeload = aggregator["Resource"][1]

    # Variable load
    @test begin
        power = Dict{Integer, Vector{AffExpr}}(3 => Vector{AffExpr}(undef, 0))
        sources = [2]
        upper_bound = [4, 5, 6]
        lower_bound = [3, 2, 1]
        id = 1        
        variableload = VariableLoad(power, sources, lower_bound, upper_bound, id)
        isa(variableload, VariableLoad)
    end
    # Constructor
    filepath = joinpath(@__DIR__, "test-systems", "variable_load_test.json")
    sys, aggregator = buildaggregator(filepath)
    variableload = aggregator["Resource"][1]
    @test isa(variableload, VariableLoad)
    # Optimization
    model = optimizeaggregator(aggregator, optimizer)
    @test isa(model, Model)
    # Min load 1 and 2, price 1 and 2, sum 5 (negative)
    @test objective_value(model) ≈ -5.0 atol= 1e-6

    # LinearTariff
    @test begin
        power = Dict{Integer, Vector{AffExpr}}(2 => Vector{AffExpr}(undef, 1))
        sources = [3]
        price = [1,2,3]
        upper_bound = [1,2,3]
        id = 1
        lineartariff = LinearTariff(power, sources, price, upper_bound, id)  
        isa(lineartariff, LinearTariff)  
    end
    # Constructor
    @test begin
        filepath = joinpath(@__DIR__, "test-systems", "lineartariff-test1.json")
        sys, aggregator = buildaggregator(filepath)
        lineartariff = aggregator["Grid"][1]
        isa(lineartariff, LinearTariff)
    end
    @test begin
        filepath = joinpath(@__DIR__, "test-systems", "lineartariff-test1.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        isa(model, Model)
    end

    # Generation - component
    @test begin
        power = Dict{Integer, Vector{AffExpr}}(2 => Vector{AffExpr}(undef, 3))
        pmax = [1,2,3]
        pmin = [0,0,1]
        id = 1
        gen = Generation(power, pmax, pmin, id)
        isa(gen, Generation)
    end
    # Generation - Constructor
    @test begin
        filepath = joinpath(@__DIR__, "test-systems", "generation-test.json")
        sys, aggregator = buildaggregator(filepath)
        gen = aggregator["Resource"][1]
        isa(gen, Generation)
    end
    # Generation - variables
    @test begin
        filepath = joinpath(@__DIR__, "test-systems", "generation-test.json")
        sys, aggregator = buildaggregator(filepath)
        model = optimizeaggregator(aggregator, optimizer)
        gen = aggregator["Resource"][1] # 1 is vector index not id
        isa(gen.power[1], Vector{VariableRef}) # 1 is node id here
    end
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

    # FCRN capacity
    # High FCR capacity price, no activation.
    # DA price [1,1]
    # Simple market price [1,0.5]
    # FCR capacity price [10,10]
    # First time step:
    # Charge battery at power = 1, battery has up_capacity 1, charger donw_capacity 1 -> FCR capacity 1
    # Revenue = 10 - 1
    # Second time step: Charger at power 1 from battery discharge. 
    # Turning off battery downregulates, turning off charger uppregulates - FCR capacity 1
    # 0.5 revenue from market
    # Revenue = 10 + 0.5
    # Total revenue 9 + 10.5 = 19.5
    # Expect half power on charger even though market price is less than DA.
    # Half power to maximize acitivity in the symmetric FCRN market
    filepath = joinpath(@__DIR__, "test-systems", "fcr3.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 19.5 atol = 1e-6

    #FCR activation test.
    # This system is to complex to easily 'see' what the solution should be and
    # is therefore not really a test. However the solution has been evaluated and
    # and seems reasonable. This is thus more a test that functionality is not 
    # changing.
    filepath = joinpath(@__DIR__, "test-systems", "fcr-activation.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 16.25 atol = 1e-6

    # Generation test
    # The system has a generation component that generates power [1,2,3]. A fixed
    # load requires power [5,5,5], An energy market supplies remaining power with
    # cost [1,2,3]. The required power from the market will be [2,3,4] resulting
    # in a total cost 1*2 + 2*3 + 3*4 = 2+6+12 = 20
    filepath = joinpath(@__DIR__, "test-systems", "generation-test2.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ -20 atol = 1e-6

    # Generation test
    # Redo above but reading gen data from a file
    filepath = joinpath(@__DIR__, "test-systems", "generation-test3.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ -20 atol = 1e-6
end;

@testset begin
    println("\n Running group tests...")
    
    # Simple FFR market
    # DA price [1,1]
    # Simple market price [1,0.5]
    # FFR price [1,1]
    # First timestep charge battery and run charger at full power.
    # -2 buy power, +2 from ffr (curtail both loads), +1 from market = +1
    # Second timestep, keep battery, charger full power
    # -1 buy power, +2 from ffr (curtail charger, discharge battery) +0.5 market = +1.5
    # Sum is +2.5
    filepath = joinpath(@__DIR__, "test-systems", "ffr1.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2.5 atol = 1e-6

    # Simple FFR market
    # Same as above but change max power in charger to 2
    # Sum is +4
    filepath = joinpath(@__DIR__, "test-systems", "ffr4.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 4.0 atol = 1e-6

    # Simple FFR market
    # Similar to above but with minimum bid for FFR set to 10 (excludes FFR)
    # DA price is set to (1,1) and market price to (1,2)
    # Max power in step 2 gives max revenue 0 + 2 = 2 
    filepath = joinpath(@__DIR__, "test-systems", "ffr5.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2 atol = 1e-6
end