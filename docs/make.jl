using Documenter
using CFTime
using Dates

makedocs(
    format = Documenter.HTML(),
    modules = [CFTime],
    sitename = "CFTime",
    pages = [
        "index.md"],
    checkdocs = :none,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.

deploydocs(
    repo = "github.com/JuliaGeo/CFTime.jl.git",
    target = "build"
)
