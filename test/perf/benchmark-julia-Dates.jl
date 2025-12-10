using Dates
using BenchmarkTools
using Statistics
using UUIDs
using Pkg

function compute(offset)
    t0 = DateTime(1900, 1, 1) .+ Dates.Second.(offset)
    t1 = DateTime(2000, 1, 1) .+ Dates.Second.(offset)

    diff = t1 - reverse(t0)

    return mean(Dates.value.(Dates.Millisecond.(diff)) ./ 1000), mean(Dates.month.(t0))
end

println("julia: ", VERSION)

pkg_name = "Dates"
m = Pkg.Operations.Context().env.manifest
println("Dates: ", m[findfirst(v -> v.name == pkg_name, m)].version)

n = 1_000_000
#n = 100_000
offset = collect(0:(n - 1))
println("mean_total_seconds: ", compute(offset))

bm = run(@benchmarkable compute(offset) samples = 100 seconds = 60)

println("min time: ", minimum(bm.times / 1.0e9))

open("julia-Dates.txt", "w") do f
    for t in bm.times
        println(f, t / 1.0e9)
    end
end
