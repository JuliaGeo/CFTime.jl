#=
using Pkg; Pkg.activate("CFTime-env",shared=true)
=#

using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple, datenum, AbstractCFDateTime, parseDT, datenum_
import Dates
import Dates: value, year,  month,  day, hour, minute, second, millisecond, microsecond, nanosecond
using Test
import Base: +, -, *, zero, one, isless, rem, div, string, convert
using Dates

using CFTime: Period, DateTimeStandard

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

dt = DateTimeStandard(1000,"milliseconds since 2000-01-01");
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTimeStandard(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTimeStandard(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTimeStandard(10^9,"nanoseconds since 2000-01-01");
@test same_tuple((2000, 1, 1, 0, 0, 1), datetuple(dt))

dt = DateTimeStandard(10^9,"nanoseconds since 2000-01-01T23:59:59")
@test same_tuple((2000, 1, 2), datetuple(dt))
@test Dates.day(dt) == 2
@test Dates.second(dt) == 0
@test Dates.millisecond(dt) == 0
@test Dates.microsecond(dt) == 0

dt = DateTimeStandard(1,"microseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 0, 0, 1),datetuple(dt))





# p1 = Microsecond(1)
# p2 = Microsecond(10)
# @test p1+p2 == Microsecond(11)


# p1 = Microsecond(1)
# p2 = Nanosecond(10)
# @test p1+p2 == Nanosecond(1010)




dt = DateTimeStandard(1,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Microsecond(1)) == 2

@test Dates.nanosecond(dt) == 0

@test Dates.nanosecond(dt + Dates.Nanosecond(1)) == 1
@test Dates.nanosecond(dt + Dates.Nanosecond(1000)) == 0

dt = DateTimeStandard(0,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Nanosecond(1000)) == 1




dt = DateTimeStandard(1,"milliseconds since 2000-01-01T23:59:59.999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTimeStandard(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTimeStandard(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))

dt = DateTimeStandard(1,"nanoseconds since 2000-01-01T23:59:59.999999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTimeStandard(2001,1,1)
@test same_tuple((2001, 1, 1), datetuple(dt))


dt = DateTimeStandard(2001,1,1 , 1,2,3,   100,200,300, units = :nanosecond)
@test same_tuple((2001, 1, 1, 1,2,3, 100,200,300), datetuple(dt))


dt = DateTimeStandard(Float32(366*24*60*60*1000),"milliseconds since 2000-01-01")
@time datetuple(dt);


dt = DateTimeStandard(Float32(24*60*60*1000),"milliseconds since 2000-01-01")

@test Dates.hour(dt) < 24
@test Dates.minute(dt) < 60
@test Dates.second(dt) < 60

#@which datetuple(dt)



# dt = DateTimeStandard(Float64(24*60*60*1000),"milliseconds since 2000-01-01")
# @time datetuple(dt);

# dt = DateTimeStandard(24*60*60*1000,"milliseconds since 2000-01-01")
# @time datetuple(dt);


#dt2 = dt + Millisecond(10);
#dt2 = dt + Millisecond(10) +  Microsecond(20) + Nanosecond(30);

dt1 = DateTimeStandard(0,"microseconds since 2000-01-01")
dt2 = DateTimeStandard(10,"microseconds since 2000-01-01")
dt3 = DateTimeStandard(2,"days since 2000-01-01")

@test (dt2 - dt1) == Dates.Microsecond(10)


@test (dt2 - dt1) == Dates.Nanosecond(10_000)

@test dt1 < dt2
@test dt1 < dt3
@test dt3 > dt1

#@btime $dt2 - $dt1


@test !(dt1 == dt2)

# dt1-dt2
dr = dt1:Dates.Microsecond(2):dt2;

@test dr[1] == dt1
@test dr[2] - dr[1] == Dates.Microsecond(2)
@test length(dr) == 6

#(dt2 - dt1) % Microsecond(2)
Delta = convert(Period,Dates.Nanosecond(10_000))

dt1 = DateTimeStandard(0,"microseconds since 2000-01-01")
#@which dt1 + Delta
# 1.92 ns
#dts = @btime $dt1 + $Delta

using Dates: UTInstant
using CFTime: DateTimeProlepticGregorian, DateTimeJulian
using CFTime: _origintuple


@test convert(DateTime,DateTimeStandard(2001,2,3)) == DateTime(2001,2,3)
@test convert(DateTime,DateTimeProlepticGregorian(2001,2,3)) == DateTime(2001,2,3)

# https://en.wikipedia.org/w/index.php?title=Conversion_between_Julian_and_Gregorian_calendars&oldid=1194423852

@test convert(DateTime,DateTimeJulian(500,2,28)) == DateTime(500,3,1)
@test convert(DateTime,DateTimeJulian(1900,3,1)) == DateTime(1900,3,14)
@test convert(DateTime,DateTimeJulian(2024,2,13)) == DateTime(2024,2,26)


@test DateTimeJulian(500,2,28) == convert(DateTimeJulian,DateTimeProlepticGregorian(500,3,1))

#@test DateTimeJulian(500,2,28) == convert(DateTimeJulian,DateTime(500,3,1))
@test DateTimeJulian(1900,3,1) == convert(DateTimeJulian,DateTimeProlepticGregorian(1900,3,14))
@test DateTimeJulian(2024,2,13) == convert(DateTimeJulian,DateTimeProlepticGregorian(2024,2,26))


@test DateTimeJulian(2024,2,13) == convert(DateTimeJulian,DateTime(2024,2,26))


@test DateTimeJulian(2024,2,13) == DateTimeProlepticGregorian(2024,2,26)


for T1 in [DateTimeProlepticGregorian,DateTimeJulian,DateTimeStandard,DateTime]
    for T2 in [DateTimeProlepticGregorian,DateTimeJulian,DateTimeStandard,DateTime]
        local dt1, dt2
        # verify that durations (even accross 1582-10-15) are maintained
        # after convert
        dt1 = [T1(2000,01,03), T1(-100,2,20)]
        dt2 = convert.(T2,dt1)
        @test dt1[2]-dt1[1] == dt2[2]-dt2[1]
    end
end



daysinmonth(DateTimeAllLeap,2001,2)

dt = DateTimeStandard(1582,10,1)
daysinmonth(DateTimeStandard,1582,10)

daysinmonth(dt)

DT = DateTimeStandard
import CFTime: DateTimeStandard, _pad3, unwrap, _factor, _exponent, _type



#function DateTimeStandard{Period{Int64, Val{1}(), Val{-3}()}, Val{(1970, 1, 1)}()}(y::Int64, m::Int64, d::Int64)


@test daysinmonth(DateTimeStandard(1582,10,1)) == 21

dt = DateTimeStandard(1582,10,1)

T = typeof(dt.instant)
Torigintuple = Val{(1970, 1, 1)}()

args = (1582,10,1)

parse(DateTimeNoLeap,"1999-12-05", dateformat"yyyy-mm-dd")

@test parse(DateTimeNoLeap,"1999-12-05", dateformat"yyyy-mm-dd") == DateTimeNoLeap(1999,12,05)

dt = DateTimeStandard(1,"nanoseconds since 2000-01-01T23:59:59.999999999")
@test same_tuple((2000, 1, 2), datetuple(dt))

tt = (
    2000,# year
    1,   # month
    2,   # day
    3,   # hour
    4,   # minute
    5,   # second
    6,   # millisecond
    7,   # microsecond
    8,   # nanosecond
    9,   # picosecond
    10,   # femtosecond
    11,   # attosecond
    12,   # zeptosecond
    13,   # yoctosecond
    14,   # rontosecond
    15,   # quectosecond
)


dt = DateTimeStandard(Int128,tt[1:12]...)
@test CFTime.attosecond(dt) == 11

if :quectosecond in CFTime.TIME_NAMES
    dt = DateTimeStandard(Int128,tt[1:15]...)
    @test CFTime.rontosecond(dt) == 14
    @test CFTime.quectosecond(dt) == 15


    dt = DateTimeStandard(BigInt,tt...)
    @test CFTime.rontosecond(dt) == 14
    @test CFTime.quectosecond(dt) == 15

    CFTime.nanosecond(dt) == 8

    dt = DateTimeStandard(Int64,tt[1:9]...)

    @show datetuple(dt)


    tt = (
        1900,# year
        1,  # month
        2,   # day
        0,   # hour
        0,   # minute
        0,   # second
        0,   # millisecond
        0,   # microsecond
        0,   # nanosecond
        0,   # picosecond
        0,   # femtosecond
        0,   # attosecond
        0,   # zeptosecond
        0,   # yoctosecond
        0,   # rontosecond
        0,   # quectosecond
    )

    dt = DateTimeStandard(Int128,tt[1:10]...)
end

using CFTime: DATETIME_OFFSET, _origin_period, _origintuple, _hasyear0
using CFTime: timetype, timedecode, _origin_period, _factor, _exponent
using CFTime: _timeunits, chop0

@test CFTime.datetuple(CFTime.timedecode(0,"days since -4713-01-01T12:00:00","julian", prefer_datetime = false)) ==
    (-4713, 1, 1, 12, 0, 0, 0)

data = 0
units = "days since -4713-01-01T12:00:00"
calendar = "julian"
DT = timetype(calendar)
dt = timedecode(DT,data,units)
@test dt.instant.duration == 0
@test CFTime.hour(dt) == 12
