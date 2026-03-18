using Test
import Dates
using Dates: DateTime
using CFTime


# rounding
dt = DateTimeStandard(24 * 60 * 60 * 1000 * 1000 + 123, "microsecond since 2000-01-01")
@test round(DateTime, dt) == DateTime(2000, 1, 2)

dt = DateTimeStandard(1, "days since 2000-01-01")
@test round(DateTime, dt) == DateTime(2000, 1, 2)

# rounding with low-precision float
dt = DateTimeStandard(1.0f0, "days since 2000-01-01")
@test round(DateTime, dt) == DateTime(2000, 1, 2)

dt = DateTimeStandard(24 * 60 * 60, "second since 2000-01-01")
@test floor(dt + Dates.Second(9), Dates.Second(10)) == dt
@test round(dt + Dates.Second(9), Dates.Second(10)) == dt + Dates.Second(10)

dt = DateTimeJulian(24 * 60 * 60, "second since 2000-01-01")
@test floor(dt + Dates.Second(9), Dates.Second(10)) == dt
@test round(dt + Dates.Second(9), Dates.Second(10)) == dt + Dates.Second(10)

dt = DateTimeStandard(24 * 60 * 60, "second since 2000-01-01 00:00:00.111222")
@test round(DateTime, dt) == DateTime(2000, 1, 2, 0, 0, 0, 111)

for DT in (DateTimeStandard, DateTimeProlepticGregorian, DateTimeJulian, DateTimeNoLeap, DateTimeAllLeap, DateTime360Day)
    local dt1, dt2, p
    for units in [:second, :millisecond]
        dt2 = DT(2000, 1, 3, 23; units)
        dt1 = DT(2000, 1, 1; units)
        p = dt2 - dt1
        @test floor(p, Dates.Day) == Dates.Day(2)
        @test floor(p, Dates.Second) == Dates.Second((2 * 24 + 23) * 60 * 60)
        @test floor(p, Dates.Millisecond) == Dates.Millisecond((2 * 24 + 23) * 60 * 60 * 1000)
        @test floor(p, Dates.Microsecond) == Dates.Microsecond((2 * 24 + 23) * 60 * 60 * 1000 * 1000)
    end
end

p1 = CFTime.Period(2, :day) + CFTime.Period(1, :second)
p2 = Dates.Second(2 * 24 * 60 * 60) + Dates.Second(1)


for p in (p1, p2)
    for pre in (CFTime.Period(1, :day), Dates.Day(1))
        for precision in (pre, typeof(pre))
            @test floor(p, precision) == Dates.Day(2)
            @test round(p, precision) == Dates.Day(2)
            @test ceil(p, precision) == Dates.Day(3)
        end
    end
end

Δt = CFTime.Period(2, :day)
@test typeof(round(Δt, Dates.Millisecond)) == Dates.Millisecond
