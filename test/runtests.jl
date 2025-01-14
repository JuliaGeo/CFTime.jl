using CFTime
using Test
using Dates
using Printf

@testset "Time and calendars" begin
    include("test_time.jl")
end

@testset "zero" begin
    @test zero(DateTimeAllLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeNoLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
end
