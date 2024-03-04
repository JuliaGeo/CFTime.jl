#using Pkg; Pkg.activate("CFTime-env",shared=true)


using CFTime
using Test

@testset "Time and calendars" begin
    include("test_time.jl")
    include("test_resolution.jl")
    include("test_aqua.jl")
end
