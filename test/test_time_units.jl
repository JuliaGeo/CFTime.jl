using CFTime
using Test

t = timedecode(0, "seconds since 2000-01-01", "proleptic_gregorian",prefer_datetime = true)
@test typeof(t) <: DateTime
@test CFTime.datetuple(t)[1:3] == (2000,1,1)

t = timedecode(1, "microseconds since 2000-01-01 00:00:00.000001", "proleptic_gregorian",prefer_datetime = false);
@test CFTime.datetuple(t)[8] == 2

t = timedecode(1, "nanoseconds since 2000-01-01", "proleptic_gregorian",prefer_datetime = false);
@test typeof(t) <: DateTimeProlepticGregorian
@test CFTime.datetuple(t)[9] == 1

t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian",prefer_datetime = false);
@test CFTime.second(t) == 1

t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian")
@test CFTime.second(t) == 1

