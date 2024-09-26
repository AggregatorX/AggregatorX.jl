using Test
using JuMP
using HiGHS
optimizer = HiGHS.Optimizer
include("AggregatorX.jl")
using .AggregatorX

@testset begin
    println("\n Running system description tests... \n ")

    # non unique ids

    # missing id
    filepath = joinpath(@__DIR__, "test-systems", "missing.json")
    @test_throws MissingIdException buildaggregator(filepath)

    # Missing market or resource
    end;

@testset begin
    println("\n Running component tests...\n")

    # FCR_N_D1
    filepath = joinpath(@__DIR__, "test-systems", "fcr1.json")
    sys,aggregator = buildaggregator(filepath)
    markets = aggregator["Market"]
    fcr_object = false
    for m in markets
        if m.class == "FCR"
            fcr_object = true
        end
    end
    @test fcr_object 
end

@testset begin
    println("\n Running basic optimality tests... \n ")

    # no revenue
    filepath = joinpath(@__DIR__, "test-systems", "no_revenue.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 0.0 atol = 1e-6

    # max power - sale price is higher than cost - max power
    # Two timesteps. DA = 1.0 constant, SimpleMarket = 2.0 constant
    # Max power = 1.0
    # Expect buy max power 1.0 with revenu 2.0-1.0 = 1.0 per time unit.
    filepath = joinpath(@__DIR__, "test-systems", "max_power.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2.0 atol = 1e-6

    # max power - sale price is higher than cost - max power
    # Max power = 1.0
    # Buy [1.2, 1.6, 2.6, 3.9]
    # Sell [2.4, 1.9, 1.2, 4.6]
    # Expect max power in timestep 1,2, and 4 with total revenue
    # 1.2 + 0.3 + 0.7 = 2.2.
    filepath = joinpath(@__DIR__, "test-systems", "max_power2.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 2.2 atol = 1e-6

    # max power when sale price is sometimes higher than cost.
    # Max power = 2.2
    # Buy [1.2, 0, 2.6, 3.9]
    # Sell [4.6, 8.2, 0, 4.6]
    # Expect max power in timestep 1,2, and 4 with total revenue
    # (3.4 + 8.2 + 0 + 0.7)*2.2 = 2.2.
    filepath = joinpath(@__DIR__, "test-systems", "max_power3.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 27.06 atol = 1e-6

    # max storage
    # If market price in time unit 2 is higher than timestep 1, and DA price
    # is higher in time unit 2, buy 
    # DA price [1,2], SimpleMarket [1,10]
    # Max storage = 1.0, Max charge/discharge = 1.0
    # Expect revenu equal 9 (buy 1, sell 10)
    filepath = joinpath(@__DIR__, "test-systems", "battery1.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 9.0 atol = 1e-6
end;

@testset begin

    #Simple FFR market
    println("\n Running group tests...")
    filepath = joinpath(@__DIR__, "test-systems", "ffr1.json")
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 3.5 atol = 1e-6
end;