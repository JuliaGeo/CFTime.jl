
using Test
using Dates: DateTime, Day, Second
using CFTime: DateTimeStandard


# rounding
dt = DateTimeStandard(24*60*60*1000*1000 + 123,"microsecond since 2000-01-01")
@test round(DateTime,dt) == DateTime(2000,1,2)

dt = DateTimeStandard(1,"days since 2000-01-01")
@test round(DateTime,dt) == DateTime(2000,1,2)

# rounding with low-precision float
dt = DateTimeStandard(1.f0,"days since 2000-01-01")
@test round(DateTime,dt) == DateTime(2000,1,2)

dt = DateTimeStandard(24*60*60,"second since 2000-01-01")
@test floor(dt+Second(9),Second(10)) == dt
@test round(dt+Second(9),Second(10)) == dt + Second(10)


dt = DateTimeStandard(24*60*60,"second since 2000-01-01 00:00:00.111222")
@test round(DateTime,dt) == DateTime(2000,1,2,0,0,0,111)
