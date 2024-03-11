using CFTime
using Test

@testset "Time and calendars" begin
    include("test_time.jl")
    include("test_resolution.jl")
    include("test_rounding.jl")
    include("test_year0.jl")
    include("test_aqua.jl")
end
