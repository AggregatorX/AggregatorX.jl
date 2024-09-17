using JuMP
using HiGHS
using Test
optimizer = HiGHS.Optimizer

include("AggregatorX.jl")
using .AggregatorX

# missing id
#joinpath(@__DIR__, "test-systems", "missing.json")
#@test_throws BoundsError buildaggregator("missing_id.jl")

# no revenue

@testset begin 
    filepath = joinpath(@__DIR__, "test-systems", "no_revenue.json")
    print(filepath)
    sys, aggregator = buildaggregator(filepath)
    model = optimizeaggregator(aggregator, optimizer)
    @test objective_value(model) ≈ 0.0 atol = 1e-6
end;