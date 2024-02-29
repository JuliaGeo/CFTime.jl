using CFTime
using Test

#t = timedecode(0, "seconds since 2000-01-01", "proleptic_gregorian",prefer_datetime = false);
#@show typeof(t)
#@time CFTime.datetuple(t)

t = @time timedecode(0, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian",prefer_datetime = false);
tt = @time CFTime.datetuple(t)
@show tt


#t = timedecode(0, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian",prefer_datetime = true);


# t = timedecode(0, "nanoseconds since 2000-01-01", "proleptic_gregorian",prefer_datetime = false);

# typeof(t)
# CFTime.datetuple(t)

#t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian",prefer_datetime = false);

# issue #18
# t = timedecode(1e9, "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian")
# @test CFTime.second(t) == 1


# t = timedecode([0,1], "nanoseconds since 2000-01-01 00:00:00.001", "proleptic_gregorian")
# @test CFTime.second(t) == 1

# t[2] - t[1]
