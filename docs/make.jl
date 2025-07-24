using Pkg
Pkg.activate(@__DIR__)
CI = get(ENV, "CI", nothing) == "true"
using Documenter
using CFTime
using Dates
import Literate

files = joinpath.(@__DIR__, "..", "examples", [
    "example_CMIP6.jl",
])

for file in files
    Literate.markdown(
        file,
        joinpath(@__DIR__, "src"),
        execute = true,
        documenter = true,
        # We add the credit to Literate.jl the footer
        credit = false,
    )
end

makedocs(
    format = Documenter.HTML(
        prettyurls = CI,
        footer = "Powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl), [Literate.jl](https://github.com/fredrikekre/Literate.jl) and the [Julia Programming Language](https://julialang.org/)",
    ),
    modules = [CFTime],
    sitename = "CFTime",
    pages = [
        "CFTime" => "index.md",
        "Example" => "example_CMIP6.md",
    ],
    checkdocs = :none,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.

deploydocs(
    repo = "github.com/JuliaGeo/CFTime.jl.git",
    target = "build"
)
