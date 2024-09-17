using Test
using JuMP
using HiGHS
optimizer = HiGHS.Optimizer
include("AggregatorX.jl")
using .AggregatorX

@testset begin
println("\n Running system description tests \n ")
# missing id
filepath = joinpath(@__DIR__, "test-systems", "missing.json")
@test_throws MissingIdException buildaggregator(filepath)
end;

@testset begin
    println("\n Running basic optimality tests \n ")
    # no revenue
    filepath = joinpath(@__DIR__, "test-systems", "no_revenue.json")
    print(filepath)
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 0.0 atol = 1e-6
end;