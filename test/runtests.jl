using CFTime
using Test

@testset verbose = true "All tests" begin
    @testset verbose = true "Time and calendars" begin
        include("test_time.jl")
    end
    @testset "Resolution" begin
        include("test_resolution.jl")
    end
    @testset "Rounding" begin
        include("test_rounding.jl")
    end
    @testset "Year 0" begin
        include("test_year0.jl")
    end
    @testset "Aqua" begin
        include("test_aqua.jl")
    end
end
