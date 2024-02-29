#using Pkg; Pkg.activate("CFTime-env",shared=true)


using CFTime
using Test
using Dates
using Printf

@testset "Time and calendars" begin
    include("test_time.jl")
    include("test_resolution.jl")
end
