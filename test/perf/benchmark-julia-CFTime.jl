using CFTime
using Dates
using BenchmarkTools
using Statistics
using UUIDs
using Pkg
using AMDGPU

cpu(x) = x
gpu(x) = roc(x)

function compute(offset)
    t0 = DateTimeProlepticGregorian(1900, 1, 1) .+ Dates.Second.(offset)
    t1 = DateTimeProlepticGregorian(2000, 1, 1) .+ Dates.Second.(offset)

    diff = t1 - reverse(t0)

    return mean(Dates.value.(Dates.Millisecond.(diff)) ./ 1000), mean(Dates.month.(t0))
end

println("julia: ", VERSION)

pkg_name = "CFTime"
m = Pkg.Operations.Context().env.manifest
println("CFTime: ", m[findfirst(v -> v.name == pkg_name, m)].version)

n = 1_000_000
#n = 100_000

for device = (cpu,gpu)
    offset = device(collect(0:(n-1)))
    #println("mean_total_seconds: ", compute(offset))

    bm = run(@benchmarkable compute($offset) samples = 100 seconds = 60)

    println("min time: ", minimum(bm.times / 1.0e9))

    open("julia-CFTime-$device.txt", "w") do f
        for t in bm.times
            println(f, t / 1.0e9)
        end
    end
end
