using Documenter
using CrystalInfoContainers

makedocs(sitename="CrystalInfoContainers documentation",
	  format = Documenter.HTML(
				   prettyurls = get(ENV,"CI",nothing) == "true"
				   ),
         pages = [
             "Overview" => "index.md",
             "Guide" => "tutorial.md",
             "API" => "api.md"
             ],
         #doctest = :fix
	  )

deploydocs(
    repo = "github.com/jamesrhester/CrystalInfoContainers.jl.git",
)
