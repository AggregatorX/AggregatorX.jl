using Documenter
using AggregatorX
using JuMP

makedocs(
	sitename="AggregatorX",
	remotes = nothing,
	pages = [
		"Introduction" => "introduction.md",
		"Design" => "design.md",
		"Internals" => "internals.md"
	]
)
