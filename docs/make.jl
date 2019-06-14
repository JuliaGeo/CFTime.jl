using Documenter
using CFTime

makedocs(
    format = Documenter.HTML(),
    modules = [CFTime],
    sitename = "CFTime",
    pages = [
        "index.md"]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.

deploydocs(
    repo = "github.com/Alexander-Barth/CFTime.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)
