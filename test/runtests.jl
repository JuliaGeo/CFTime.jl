using CFTime
if VERSION >= v"0.7.0-beta.0"
    using Test
    using Dates
    using Printf
else
    using Base.Test
    using Compat
end



@testset "Time and calendars" begin
    include("test_time.jl")
end
