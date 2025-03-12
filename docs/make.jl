using Documenter
using CrystalInfoContainers

makedocs(sitename="CrystalInfoContainers documentation",
	  format = Documenter.HTML(), pages = [
             "Overview" => "index.md",
             "Guide" => "tutorial.md",
             "API" => "api.md"
             ],
	  # doctests fail on Github, output width for dataframes is different
	  doctest = false 
	)

deploydocs(
    repo = "github.com/jamesrhester/CrystalInfoContainers.jl.git",
)
