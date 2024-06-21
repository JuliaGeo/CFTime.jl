using CFTime
using Dates
using BenchmarkTools
using Statistics

function compute(n)
    t0 = DateTimeStandard(1000,1,1) .+ Dates.Second.(0:(n-1))
    t1 = DateTimeStandard(2000,1,1) .+ Dates.Second.(0:(n-1))

    diff = t1 - reverse(t0)

    return mean(Dates.value.(Dates.Millisecond.(diff)))
end

n = 1_000_000
@show compute(n)

bm = run(@benchmarkable compute(n) samples=100 seconds=10000)

@show bm
@show minimum(bm.times/1e9)

open("julia-CFTime.txt","w") do f
    for t in bm.times
        println(f,t/1e9)
    end
end
