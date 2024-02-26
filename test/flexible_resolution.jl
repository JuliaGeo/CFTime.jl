using Pkg

Pkg.activate("CFTime-env",shared=true)

using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple, datenum, AbstractCFDateTime, parseDT
import Dates
import Dates: value, year,  month,  day, hour, minute, second, millisecond, microsecond, nanosecond
using Test
using BenchmarkTools
import Base: +, -, *, zero, one, isless, rem, div, string, convert
using Dates

using CFTime: Period, DateTime2


# TEST


function same_tuple(t1,t2)
    len = min(length(t1),length(t2))
     (t1[1:len] == t2[1:len]) &&
         all(==(0),t1[len+1:end]) &&
         all(==(0),t2[len+1:end])
end



@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5)*1000,1))[1:4] == (2,3,4,5)

@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5),1000))[1:4] == (2,3,4,5)

factor = 1000

#for tuf in (
#    (2,3,4,5),
tuf=    (2,3,4,5,6,7,8)
#    )
factor = 1e-6
exponent = -3

p = Period(tuf,factor)
@test timetuplefrac(p)[1:length(tuf)] == tuf


factor = 1
exponent = -9

p = Period(tuf,factor,exponent)
@test timetuplefrac(p)[1:length(tuf)] == tuf


#end


@btime datenum_($tuf,$factor,0)

#@btime tf($time,$divi)


#@code_warntype tf(time,divi)

#@test tf(time,divi)[1:4] == (2,3,4,5)



dt = DateTime2(1000,"milliseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01");
@test same_tuple((2000, 1, 1, 0, 0, 1), datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01T23:59:59")
@test same_tuple((2000, 1, 2), datetuple(dt))
@test Day(dt) == 2
@test Second(dt) == 0
@test Millisecond(dt) == 0
@test Microsecond(dt) == 0


dt = DateTime2(1,"microseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 0, 0, 1),datetuple(dt))





# p1 = Microsecond(1)
# p2 = Microsecond(10)
# @test p1+p2 == Microsecond(11)


# p1 = Microsecond(1)
# p2 = Nanosecond(10)
# @test p1+p2 == Nanosecond(1010)




dt = DateTime2(1,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Microsecond(1)) == 2

@test Dates.nanosecond(dt) == 0

@test Dates.nanosecond(dt + Dates.Nanosecond(1)) == 1
@test Dates.nanosecond(dt + Dates.Nanosecond(1000)) == 0

dt = DateTime2(0,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Nanosecond(1000)) == 1




dt = DateTime2(1,"milliseconds since 2000-01-01T23:59:59.999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))

dt = DateTime2(1,"nanoseconds since 2000-01-01T23:59:59.999999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(2001,1,1)
@test same_tuple((2001, 1, 1), datetuple(dt))


dt = DateTime2(2001,1,1 , 1,2,3,   100,200,300, unit = :nanosecond)
@test same_tuple((2001, 1, 1, 1,2,3, 100,200,300), datetuple(dt))


dt = DateTime2(Float32(366*24*60*60*1000),"milliseconds since 2000-01-01")
@time datetuple(dt);


dt = DateTime2(Float32(24*60*60*1000),"milliseconds since 2000-01-01")

@test Dates.hour(dt) < 24
@test Dates.minute(dt) < 60
@test Dates.second(dt) < 60

@which datetuple(dt)



# dt = DateTime2(Float64(24*60*60*1000),"milliseconds since 2000-01-01")
# @time datetuple(dt);

# dt = DateTime2(24*60*60*1000,"milliseconds since 2000-01-01")
# @time datetuple(dt);


#dt2 = dt + Millisecond(10);
#dt2 = dt + Millisecond(10) +  Microsecond(20) + Nanosecond(30);

dt1 = DateTime2(0,"microseconds since 2000-01-01")
dt2 = DateTime2(10,"microseconds since 2000-01-01")

#Dates.Microsecond(10) == (dt2 - dt1)

#@btime $dt2 - $dt1


#dt1 == dt2

# dt1-dt2
#=
dr = dt1:Dates.Microsecond(2):dt2;
#first(dr)
#@which length(dr)
length(dr)


(dt2 - dt1) % Microsecond(2)

import Dates
dr = Dates.DateTime(2000,1,1):Dates.Day(1):Dates.DateTime(2000,1,1)
=#
