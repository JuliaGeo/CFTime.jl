using CFTime
using Test

t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian",prefer_datetime = false);

# issue #18
# t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian")
# @test CFTime.second(t) == 1


# t = timedecode([0,1], "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian")
# @test CFTime.second(t) == 1

# t[2] - t[1]
