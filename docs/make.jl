using Documenter
using AggregatorX
using JuMP

makedocs(
	sitename="AggregatorX",
	remotes = nothing,
	pages = [
		"Introduction" => "introduction.md",
		"Design" => "design.md",
		"Groups" => "groups.md",
		"Internals" => "internals.md"
	],
	format = Documenter.HTML(;
        mathengine = Documenter.MathJax(Dict(
            :TeX => Dict(
                :equationNumbers => Dict(:autoNumber => "AMS"),
            ),
        ))
    )
)
