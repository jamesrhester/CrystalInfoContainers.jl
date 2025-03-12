using Documenter
using CrystalInfoContainers

makedocs(sitename="CrystalInfoContainers documentation",
	  format = Documenter.HTML(), pages = [
             "Overview" => "index.md",
             "Guide" => "tutorial.md",
             "API" => "api.md"
             ],
	  #doctest = :fix
	)

deploydocs(
    repo = "github.com/jamesrhester/CrystalInfoContainers.jl.git",
)
