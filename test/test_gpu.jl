using CFTime
using CUDA
using Dates
using Test

# periods

p1 = [CFTime.Period{Int64, Val{1}(), Val{0}()}(1)]
p2 = [CFTime.Period{Int64, Val{1}(), Val{-3}()}(1)]

@test p1 .+ p2 == Array(cu(p1) .+ cu(p2))


p1 = [CFTime.Period{Int64, Val{86400}(), Val{0}()}(1)]
p2 = [CFTime.Period{Int64, Val{1}(), Val{-3}()}(1)]


@test p1 .+ p2 == Array(cu(p1) .+ cu(p2))


# periods and datetime

dt = [DateTimeStandard(2000,1,1)]; t = CFTime.Period.([1],:second);


@test dt + t == Array(cu(dt) + cu(t))


dt_cpu = [DateTimeStandard(2000,1,1,origin=(1970,1,1))]
dt_gpu = cu(dt_cpu)

@test Array(CFTime._origin_period.(dt_gpu)) == CFTime._origin_period.(dt_cpu)

# datetime

dt = [DateTimeStandard(2000,1,1)];
dt2 =  [DateTimeStandard(2001,1,1)];

@test dt2 - dt == Array(cu(dt2) - cu(dt))


@test Array(Dates.year.(cu(dt))) == Dates.year.(dt)
@test Array(Dates.month.(cu(dt))) == Dates.month.(dt)
@test Array(Dates.day.(cu(dt))) == Dates.day.(dt)
@test Array(Dates.minute.(cu(dt))) == Dates.minute.(dt)

