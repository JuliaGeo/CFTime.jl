
using Test
using Dates: DateTime, Day, Microsecond, Second
using CFTime: DateTimeStandard


# rounding
dt = DateTimeStandard(24*60*60*1000*1000 + 123,"microsecond since 2000-01-01")
@test round(DateTime,dt) == DateTime(2000,1,2)

dt = DateTimeStandard(24*60*60+8,"second since 2000-01-01")
p = Second(10)

@test floor(dt,p) == DateTimeStandard(24*60*60,"second since 2000-01-01")
@test round(dt,p) == DateTimeStandard(24*60*60+10,"second since 2000-01-01")

