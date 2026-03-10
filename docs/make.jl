using Documenter
using AggregatorX
using JuMP

makedocs(
	sitename="AggregatorX",
	remotes = nothing,
	pages = [
		"Introduction" => "index.md",
		"Tutorial" => "tutorial.md",
		"Design" => "design.md",
		"System description" => [
			"Input file (*.json)" => "input_file.md",
			"Parsing input" => "parse_data.md",
		],
		"Groups" => "groups.md",
		"Components" => [
			"Resources" => "resources.md",
			"Markets" => "markets.md"
		],
		"New components" => "new_components.md",
		"Internals" => [
			"Repository structre" => "repo_structure.md"
			"Internals" => "internals.md"
		]
	],
	format = Documenter.HTML(;
        mathengine = Documenter.MathJax(Dict(
            :TeX => Dict(
                :equationNumbers => Dict(:autoNumber => "AMS"),
            ),
        ))
    )
)
