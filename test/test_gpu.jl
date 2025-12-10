#using Pkg
#Pkg.activate("CUDA-CFTime", shared = true)

using CFTime
#using CUDA; gpu = cu
using AMDGPU; gpu = roc
using Dates
using Test

# periods


p1 = [CFTime.Period{Int64, Val{1}(), Val{0}()}(1)]
p2 = [CFTime.Period{Int64, Val{1}(), Val{-3}()}(1)]

@test p1 .+ p2 == Array(gpu(p1) .+ gpu(p2))


p1 = [CFTime.Period{Int64, Val{86400}(), Val{0}()}(1)]
p2 = [CFTime.Period{Int64, Val{1}(), Val{-3}()}(1)]


@test p1 .+ p2 == Array(gpu(p1) .+ gpu(p2))


# periods and datetime

dt = [DateTimeStandard(2000, 1, 1)];
t = CFTime.Period.([1], :second);


@test dt + t == Array(gpu(dt) + gpu(t))

# datetime

dt = [DateTimeStandard(2000, 1, 1)];
dt2 = [DateTimeStandard(2001, 1, 1)];

@test dt2 - dt == Array(gpu(dt2) - gpu(dt))


@test Array(Dates.year.(gpu(dt))) == Dates.year.(dt)
@test Array(Dates.month.(gpu(dt))) == Dates.month.(dt)
@test Array(Dates.day.(gpu(dt))) == Dates.day.(dt)
@test Array(Dates.minute.(gpu(dt))) == Dates.minute.(dt)


N = 10_000_0000

dt1 = DateTimeStandard(2000, 1, 1) .+ Dates.Day.(rand(1:10000, N));
dt2 = DateTimeStandard(2000, 1, 1) .+ Dates.Day.(rand(1:10000, N));

dt1_d = gpu(dt1);
dt2_d = gpu(dt2);

diff = @time dt1 - dt2;
#  LUMI
#  0.474975 seconds (11 allocations: 762.942 MiB, 14.81% gc time)

diff_d = @time AMDGPU.@sync dt1_d - dt2_d;
#  0.092592 seconds (8.62 k allocations: 451.719 KiB, 2 lock conflicts, 34.25% compilation time: <1% of which was recompilation)

@test diff == Array(diff_d)


using BenchmarkTools
diff = @benchmark dt1 - dt2;


# @benchmark dt1 - dt2
# BenchmarkTools.Trial: 12 samples with 1 evaluation per sample.
#  Range (min … max):  400.701 ms … 477.954 ms  ┊ GC (min … max): 0.50% … 15.44%
#  Time  (median):     440.453 ms               ┊ GC (median):    9.33%
#  Time  (mean ± σ):   440.315 ms ±  19.024 ms  ┊ GC (mean ± σ):  8.91% ±  4.42%

#                                 ▂█
#   ▅▁▁▁▁▁▁▁▁▁▁▁▁▁▅▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▅▁▁▁▁▁▁▁▁▁▁▅ ▁
#   401 ms           Histogram: frequency by time          478 ms <

#  Memory estimate: 762.94 MiB, allocs estimate: 3.

@benchmark AMDGPU.@sync dt1_d - dt2_d
# BenchmarkTools.Trial: 207 samples with 1 evaluation per sample.
#  Range (min … max):   2.209 ms … 27.777 ms  ┊ GC (min … max): 0.00% … 0.00%
#  Time  (median):     26.918 ms              ┊ GC (median):    0.00%
#  Time  (mean ± σ):   24.145 ms ±  7.628 ms  ┊ GC (mean ± σ):  0.06% ± 1.54%

#   ▁                                                        ▁█
#   █▇▄▁▁▄▁▁▁▁▁▁▁▁▁▄▁▄▄▁▁▁▁▁▄▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▅██ ▅
#   2.21 ms      Histogram: log(frequency) by time      27.2 ms <

#  Memory estimate: 10.06 KiB, allocs estimate: 403.


year = rand(1:2000, N)
month = rand(1:12, N)
day = rand(1:20, N)

dt1 = @btime DateTimeStandard.(year, month, day)
# 829.393 ms (4 allocations: 762.94 MiB)
# 787.279 ms (4 allocations: 762.94 MiB)

year_d, month_d, day_d = gpu.((year, month, day))

dt1_d = @btime DateTimeStandard.(year_d, month_d, day_d)
#  22.885 μs (100 allocations: 3.83 KiB)
#  14.448 μs (105 allocations: 4.20 KiB)

@test Array(dt1_d) == Array(dt1)
