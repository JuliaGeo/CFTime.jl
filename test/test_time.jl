using CFTime
import Dates
using Dates: DateTime, Day, @dateformat_str
using Test

# slow, but accurate and easy to understand (and possibly fix)
include("reference_algorithm.jl")

# reference value from Meeus, Jean (1998)
# launch of Sputnik 1

@test CFTime.datetuple_ymd(DateTimeStandard,2_436_116 - 2_400_001) == (1957, 10, 4)
@test CFTime.datenum_gregjulian(1957,10,4,true) == 36115

@test CFTime.datenum_gregjulian(333,1,27,false) == -557288


function datenum_datetuple_all_calendars(::Type{T}) where T
    #dayincrement = 11
    dayincrement = 11000

    for Z = -2_400_000 + CFTime.DATENUM_OFFSET : dayincrement : 600_000 + CFTime.DATENUM_OFFSET
        y,m,d = CFTime.datetuple_ymd(T,Z)
        Z2 = CFTime.datenum(T,y,m,d)
        if Z2 !== Z
            @show Z2, (y,m,d), Z
        end
        @test Z2 == Z
    end
end

for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]
    datenum_datetuple_all_calendars(T)
end
# test of DateTime structures

dt = DateTimeNoLeap(1959,12,31,23,39,59,123)
@test dt + Dates.Millisecond(7) == DateTimeNoLeap(1959,12,31,23,39,59,130)
@test dt + Dates.Second(7)      == DateTimeNoLeap(1959,12,31,23,40,6,123)
@test dt + Dates.Minute(7)      == DateTimeNoLeap(1959,12,31,23,46,59,123)
@test dt + Dates.Hour(7)        == DateTimeNoLeap(1960,1,1,6,39,59,123)
@test dt + Dates.Day(7)         == DateTimeNoLeap(1960,1,7,23,39,59,123)
@test dt + Dates.Month(7)       == DateTimeNoLeap(1960,7,31,23,39,59,123)
@test dt + Dates.Year(7)        == DateTimeNoLeap(1966,12,31,23,39,59,123)
@test dt + Dates.Month(24)      == DateTimeNoLeap(1961,12,31,23,39,59,123)

@test dt - Dates.Month(0)       == DateTimeNoLeap(1959,12,31,23,39,59,123)
@test dt - Dates.Month(24)      == DateTimeNoLeap(1957,12,31,23,39,59,123)
@test dt - Dates.Year(7)        == DateTimeNoLeap(1952,12,31,23,39,59,123)

# leap day
@test DateTimeAllLeap(2001,2,28) + Dates.Day(1) == DateTimeAllLeap(2001,2,29)
@test DateTimeNoLeap(2001,2,28)  + Dates.Day(1) == DateTimeNoLeap(2001,3,1)
@test DateTimeJulian(2001,2,28)  + Dates.Day(1) == DateTimeJulian(2001,3,1)
@test DateTimeJulian(1900,2,28)  + Dates.Day(1) == DateTimeJulian(1900,2,29)
@test DateTime360Day(2001,2,28)     + Dates.Day(1) == DateTime360Day(2001,2,29)
@test DateTime360Day(2001,2,29)     + Dates.Day(1) == DateTime360Day(2001,2,30)



@test DateTimeAllLeap(2001,2,29) - DateTimeAllLeap(2001,2,28) == Dates.Day(1)
@test DateTimeNoLeap(2001,3,1)   - DateTimeNoLeap(2001,2,28)  == Dates.Day(1)
@test DateTimeJulian(2001,3,1)   - DateTimeJulian(2001,2,28)  == Dates.Day(1)
@test DateTimeJulian(1900,2,29)  - DateTimeJulian(1900,2,28)  == Dates.Day(1)
@test DateTime360Day(2001,2,29)     - DateTime360Day(2001,2,28)     == Dates.Day(1)
@test DateTime360Day(2001,2,30)     - DateTime360Day(2001,2,29)     == Dates.Day(1)


# reference values from python's cftime
@test DateTimeJulian(2000,1,1) + Dates.Day(1) == DateTimeJulian(2000,01,02)
@test DateTimeJulian(2000,1,1) + Dates.Day(12) == DateTimeJulian(2000,01,13)
@test DateTimeJulian(2000,1,1) + Dates.Day(123) == DateTimeJulian(2000,05,03)
@test DateTimeJulian(2000,1,1) + Dates.Day(1234) == DateTimeJulian(2003,05,19)
@test DateTimeJulian(2000,1,1) + Dates.Day(12345) == DateTimeJulian(2033,10,19)
@test DateTimeJulian(2000,1,1) + Dates.Day(12346) == DateTimeJulian(2033,10,20)
@test DateTimeJulian(1,1,1) + Dates.Day(1234678) == DateTimeJulian(3381,05,14)


# handling of year zero, reference values
# from pythons cftime 1.6.0
# issue #17

@test DateTimeProlepticGregorian(1,1,1) - Day(1) == DateTimeProlepticGregorian(0,12,31)
@test DateTimeJulian(1,1,1) - Day(1) == DateTimeJulian(-1,12,31)
@test DateTimeStandard(1,1,1) - Day(1) == DateTimeStandard(-1,12,31)
@test DateTimeAllLeap(1,1,1) - Day(1) == DateTimeAllLeap(0,12,31)
@test DateTimeNoLeap(1,1,1) - Day(1) == DateTimeNoLeap(0,12,31)
@test DateTime360Day(1,1,1) - Day(1) == DateTime360Day(0,12,30)


# generic tests
function stresstest_DateTime(::Type{DT}) where DT
    t0 = DT(1,1,1)
    for n = -800000:11:800000
        #@show n
        t = t0 + Dates.Day(n)
        y, m, d, h, mi, s, ms = CFTime.datetuple(t)
        @test DT(y, m, d, h, mi, s, ms) == t
    end
end

for DT in [
    DateTimeStandard,
    DateTimeJulian,
    DateTimeProlepticGregorian,
    DateTimeAllLeap,
    DateTimeNoLeap,
    DateTime360Day
]

    dtime = DT(1959,12,30, 23,39,59,123)
    @test Dates.year(dtime) == 1959
    @test Dates.month(dtime) == 12
    @test Dates.day(dtime) == 30
    @test Dates.hour(dtime) == 23
    @test Dates.minute(dtime) == 39
    @test Dates.second(dtime) == 59
    @test Dates.millisecond(dtime) == 123

    @test string(DT(2001,2,20)) == "2001-02-20T00:00:00"
    @test CFTime.datetuple(DT(1959,12,30,23,39,59,123)) == (1959,12,30,23,39,59,123)

    stresstest_DateTime(DT)
end

@test_throws ErrorException DateTime360Day(2010,0,1)
@test_throws ErrorException DateTime360Day(2010,1,0)



# test show
io = IOBuffer()
show(io,DateTimeJulian(-1000,1,1))
@test isempty(findfirst("Julian",String(take!(io)))) == false


# time

t0,plength = CFTime.timeunits("days since 1950-01-02T03:04:05Z")
@test t0 == DateTimeStandard(1950,1,2, 3,4,5)
@test plength == 86400000


t0,plength = CFTime.timeunits("days since -4713-01-01T00:00:00Z")
@test t0 == DateTimeStandard(-4713,1,1)
@test plength == 86400000


t0,plength = CFTime.timeunits("days since -4713-01-01")
@test t0 == DateTimeStandard(-4713,1,1)
@test plength == 86400000


t0,plength = CFTime.timeunits("days since 2000-01-01 0:0:0")
@test t0 == DateTimeStandard(2000,1,1)
@test plength == 86400000

t0,plength = CFTime.timeunits("days since 2000-01-01 00:00")
@test t0 == DateTimeStandard(2000,1,1)
@test plength == 86400000

# issue 24
t0,plength = CFTime.timeunits("hours since 1900-01-01 00:00:00.0")
@test t0 == DateTimeStandard(1900,1,1)
@test plength == 86400000 ÷ 24


t0,plength = CFTime.timeunits("seconds since 1992-10-8 15:15:42.5")
@test t0 == DateTimeStandard(1992,10,8,15,15,42,500)
@test plength == 1000

units = "microseconds since 2000-01-01T23:59:59.12345678"
origintuple, ratio = timeunits(Tuple,units)
@test origintuple == (2000, 1, 1, 23, 59, 59, 123, 456, 780)


for (calendar,DT) in [
    ("standard",DateTimeStandard),
    ("gregorian",DateTimeStandard),
    ("proleptic_gregorian",DateTimeProlepticGregorian),
    ("julian",DateTimeJulian),
    ("noleap",DateTimeNoLeap),
    ("365_day",DateTimeNoLeap),
    ("all_leap",DateTimeAllLeap),
    ("366_day",DateTimeAllLeap),
    ("360_day",DateTime360Day)]

    calendart0,calendarplength = CFTime.timeunits("days since 2000-1-1 0:0:0",calendar)
    @test calendart0 == DT(2000,1,1)
    @test calendarplength == 86400000
end

@test_throws ErrorException CFTime.timeunits("fortnights since 2000-01-01")
@test_throws ErrorException CFTime.timeunits("days since 2000-1-1 0:0:0","foo")

# value from python's cftime
# print(cftime.DatetimeJulian(-4713,1,1) + datetime.timedelta(2455512,.375 * 24*60*60))
# 2010-10-29 09:00:00

#@test timedecode([2455512.375],"days since -4713-01-01T00:00:00","julian")
#   == DateTimeJulian(2010,10,29,09)

# values from
# https://web.archive.org/web/20180212214229/https://en.wikipedia.org/wiki/Julian_day

# Modified JD
@test CFTime.timedecode([58160.6875],"days since 1858-11-17","standard" )==
    [DateTime(2018,2,11,16,30,0)]

# CNES JD
@test CFTime.timedecode([24878.6875],"days since 1950-01-01","standard") ==
    [DateTime(2018,2,11,16,30,0)]

# Unix time
# wikipedia pages reports 1518366603 but it should be 1518366600
@test CFTime.timedecode([1518366600],"seconds since 1970-01-01","standard") ==
    [DateTime(2018,2,11,16,30,0)]


# The Julian Day Number (JDN) is the integer assigned to a whole solar day in
# the Julian day count starting from noon Universal time, with Julian day
# number 0 assigned to the day starting at noon on Monday, January 1, 4713 BC,
# proleptic Julian calendar (November 24, 4714 BC, in the proleptic Gregorian
# calendar),

# Julian Day Number of 12:00 UT on January 1, 2000, is 2 451 545
# https://web.archive.org/web/20180613200023/https://en.wikipedia.org/wiki/Julian_day


@test CFTime.timedecode(DateTimeStandard,2_451_545,"days since -4713-01-01T12:00:00") ==
    DateTimeStandard(2000,01,01,12,00,00)

# Note for DateTime, 1 BC is the year 0!
# DateTime(1,1,1)-Dates.Day(1)
# 0000-12-31T00:00:00

@test CFTime.timedecode(DateTime,2_451_545,"days since -4713-11-24T12:00:00") ==
    DateTime(2000,01,01,12,00,00)

if CFTime._hasyear0(CFTime.DateTimeProlepticGregorian)
    units = "days since -4713-11-24T12:00:00"
else
    units = "days since -4714-11-24T12:00:00"
end
@test CFTime.timedecode(DateTimeProlepticGregorian,2_451_545,units) ==
    DateTimeProlepticGregorian(2000,01,01,12,00,00)


@test CFTime.timedecode([2455512.375],"days since -4713-01-01T00:00:00","julian", prefer_datetime = false) ==
    [DateTimeJulian(2010,10,29,9,0,0)]

@test CFTime.timeencode([DateTimeJulian(2010,10,29,9,0,0)],"days since -4713-01-01T00:00:00","julian") ==
    [2455512.375]


@test CFTime.timedecode(DateTime,[22280.0f0],"days since 1950-01-01 00:00:00") == [DateTime(2011,1,1)]

@test_throws ErrorException CFTime.timeencode(
    [DateTimeJulian(2010,10,29,9,0,0)],
    "days since -4713-01-01T00:00:00","360_day")

# Transition between Julian and Gregorian Calendar

#=
In [11]: cftime.DatetimeGregorian(1582,10,4) + datetime.timedelta(1)
Out[11]: cftime.DatetimeGregorian(1582, 10, 15, 0, 0, 0, 0, -1, 1)

In [12]: cftime.DatetimeProlepticGregorian(1582,10,4) + datetime.timedelta(1)
Out[12]: cftime.DatetimeProlepticGregorian(1582, 10, 5, 0, 0, 0, 0, -1, 1)

In [13]: cftime.DatetimeJulian(1582,10,4) + datetime.timedelta(1)
Out[13]: cftime.DatetimeJulian(1582, 10, 5, 0, 0, 0, 0, -1, 1)
=#

@test DateTimeStandard(1582,10,4) + Dates.Day(1) == DateTimeStandard(1582,10,15)
@test DateTimeProlepticGregorian(1582,10,4) + Dates.Day(1) == DateTimeProlepticGregorian(1582,10,5)
@test DateTimeJulian(1582,10,4) + Dates.Day(1) == DateTimeJulian(1582,10,5)




@test CFTime.datetuple(CFTime.timedecode(0,"days since -4713-01-01T12:00:00","julian", prefer_datetime = false)) ==
    (-4713, 1, 1, 12, 0, 0, 0)


dt = CFTime.reinterpret(DateTimeStandard, DateTimeJulian(1900,2,28))
@test typeof(dt) <: DateTimeStandard
@test CFTime.datetuple(dt) == (1900,2,28,0, 0, 0, 0)

dt = CFTime.reinterpret(DateTime, DateTimeNoLeap(1900,2,28))
@test typeof(dt) == DateTime
@test Dates.year(dt) == 1900
@test Dates.month(dt) == 2
@test Dates.day(dt) == 28

dt = CFTime.reinterpret(DateTimeNoLeap, DateTime(1900,2,28))
@test typeof(dt) <: DateTimeNoLeap
@test Dates.year(dt) == 1900
@test Dates.month(dt) == 2
@test Dates.day(dt) == 28

# check ordering

@test DateTimeStandard(2000,01,01) < DateTimeStandard(2000,01,02)
@test DateTimeStandard(2000,01,01) ≤ DateTimeStandard(2000,01,01)

@test DateTimeStandard(2000,01,03) > DateTimeStandard(2000,01,02)
@test DateTimeStandard(2000,01,03) ≥ DateTimeStandard(2000,01,01)

import CFTime: datetuple
datetuple(dt::DateTime) = (Dates.year(dt),Dates.month(dt),Dates.day(dt),
                           Dates.hour(dt),Dates.minute(dt),Dates.second(dt),
                           Dates.millisecond(dt))


# check conversion

for T1 in [DateTimeProlepticGregorian,DateTimeStandard,DateTime]
    for T2 in [DateTimeProlepticGregorian,DateTimeStandard,DateTime]
        local dt1, dt2
        # datetuple should not change after 1582-10-15
        # for Gregorian Calendars
        dt1 = T1(2000,01,03)
        dt2 = convert(T2,dt1)

        @test CFTime.datetuple(dt1) == CFTime.datetuple(dt2)
    end
end


for T1 in [DateTimeStandard,DateTimeJulian]
    for T2 in [DateTimeStandard,DateTimeJulian]
        local dt1, dt2
        # datetuple should not change before 1582-10-15
        # for Julian Calendars
        dt1 = T1(200,01,03)
        dt2 = convert(T2,dt1)

        @test CFTime.datetuple(dt1) == CFTime.datetuple(dt2)
    end
end

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



# issue #12

units = "days since 1850-01-01 00:00:00"
calendar = "noleap"
data_orig = [54750.5, 54751.5, 54752.5]

# Decoding
datacal = CFTime.timedecode(data_orig, units, calendar)
# Reencoding
data_orig_back = CFTime.timeencode(datacal, units, calendar)
@test data_orig ≈ data_orig_back


# issue #17

# reference values from cftime
# for T in [cftime.DatetimeGregorian,cftime.DatetimeJulian,cftime.DatetimeProlepticGregorian,cftime.DatetimeAllLeap,cftime.DatetimeNoLeap, cftime.Datetime360Day]:
#     print(T,T(1582,11,1) - T(1582,10,1))

@test daysinmonth(DateTimeStandard(1582,10,1)) == 21
@test daysinmonth(DateTimeJulian(1582,10,1)) == 31
@test daysinmonth(DateTimeProlepticGregorian(1582,10,1)) == 31
@test daysinmonth(DateTimeAllLeap(1582,10,1)) == 31
@test daysinmonth(DateTimeNoLeap(1582,10,1)) == 31
@test daysinmonth(DateTime360Day(1582,10,1)) == 30

# import cftime
# for T in [cftime.DatetimeGregorian,cftime.DatetimeJulian,cftime.DatetimeProlepticGregorian,cftime.DatetimeAllLeap,cftime.DatetimeNoLeap, cftime.Datetime360Day]:
#    print(T,T(1583,1,1) - T(1582,1,1))

@test daysinyear(DateTimeStandard(1582,10,1)) == 355
@test daysinyear(DateTimeJulian(1582,10,1)) == 365
@test daysinyear(DateTimeProlepticGregorian(1582,10,1)) == 365
@test daysinyear(DateTimeAllLeap(1582,10,1)) == 366
@test daysinyear(DateTimeNoLeap(1582,10,1)) == 365
@test daysinyear(DateTime360Day(1582,10,1)) == 360


for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]
    @test Dates.yearmonthday(T(2004,1,2)) == (2004, 1, 2)
    @test Dates.yearmonth(T(2004,1,2)) == (2004, 1)
    @test Dates.monthday(T(2004,1,2)) == (1, 2)

    # test constructor with argument which are not Int64
    @test T(Int16(2000),Int32(1),UInt8(1)) == T(2000,1,1)
end

# time ranges

@test length(DateTimeNoLeap(2000, 01, 01):Dates.Day(1):DateTimeNoLeap(2000, 12, 31)) == 365
@test length(DateTimeNoLeap(2000, 01, 01):Dates.Month(1):DateTimeNoLeap(2000, 12, 31)) == 12

for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]

    # end date is inclusive
    @test length(T(2000, 01, 01):Dates.Month(1):T(2001, 1, 1)) == 13
    @test length(T(2000, 01, 01):Dates.Year(1):T(2001, 1, 1)) == 2
end

# issue #21
@test parse(DateTimeNoLeap,"1999-12-05", dateformat"yyyy-mm-dd") == DateTimeNoLeap(1999,12,05)
@test DateTimeNoLeap("1999-12-05", "yyyy-mm-dd") == DateTimeNoLeap(1999,12,05)
@test DateTimeNoLeap("1999-12-05", dateformat"yyyy-mm-dd") == DateTimeNoLeap(1999,12,05)

# issue #29
@test Dates.firstdayofyear(DateTimeNoLeap(2008, 12, 31)) == DateTimeNoLeap(2008, 1, 1)
@test Dates.dayofyear(DateTimeNoLeap(2008, 12, 31)) == 365
@test Dates.dayofmonth(DateTimeAllLeap(2008, 2, 29)) == 29



# issue #3

data = [0,1,2,3]
dt = CFTime.timedecode(DateTime,data,"days since 2000-01-01 00:00:00")
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00",DateTime)
@test data == data2

data = [0,1,2,3]
dt = CFTime.timedecode(DateTime360Day,data,"days since 2000-01-01 00:00:00")
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00",DateTime360Day)
@test data == data2

# issue #6

data = [0,1,2,3]
dt = CFTime.timedecode(DateTime,data,"days since 2000-01-01 00:00:00+00")
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00+00",DateTime)
@test data == data2

data = [0,1,2,3]
dt = CFTime.timedecode(DateTime360Day,data,"days since 2000-01-01 00:00:00+00:00")
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00+00:00",DateTime360Day)
@test data == data2

data = [0,1,2,3]
dt = @test_logs (:warn,r"Time zones are currently not supported.*") begin
    CFTime.timedecode(DateTime,data,"days since 2000-01-01 00:00:00+01")
end
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00+00",DateTime)
@test data == data2

data = [0,1,2,3]
dt = @test_logs (:warn,r"Time zones are currently not supported.*") begin
    CFTime.timedecode(DateTime360Day,data,"days since 2000-01-01 00:00:00-01:00")
end
data2 = CFTime.timeencode(dt,"days since 2000-01-01 00:00:00+00:00",DateTime360Day)
@test data == data2


# convertion when substracting dates
@test DateTimeStandard(2000,1,1) - DateTime(2000,1,1) == Dates.Day(0)
@test DateTime(2000,1,1) - DateTimeStandard(2000,1,1) == Dates.Day(0)
@test DateTimeStandard(2000,1,1) - DateTimeProlepticGregorian(2000,1,1) == Dates.Day(0)


# issue #16

for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]

    @test Dates.month(T(300, 3, 1)) == 3
    @test Dates.month(T(-101, 3, 1)) == 3
    @test Dates.month(T(-501, 3, 1)) == 3
    @test Dates.month(T(-901, 3, 1)) == 3
end


# comparision with reference algorithm
#Δ = 1
Δ = 1000

for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]
    local Z, MYMD, RYMD
    Z = CFTime.datenum(T,-1000,1,1):Δ:CFTime.datenum(T,4000,1,1)
    MYMD = CFTime.datetuple_ymd.(T,Z);
    RYMD = Reference.datetuple_ymd.(T,Z);
    @test MYMD == RYMD
end

#=
for dt = DateTime(-1000,1,1):Day(100):DateTime(2300,3,1)

    y = year(dt)

    dt1 = DateTimeProlepticGregorian(y,month(dt),day(dt))

    if (y,month(dt),day(dt)) !== (year(dt1),month(dt1),day(dt1))
        @show dt
        @test (y,month(dt),day(dt)) !== (year(dt1),month(dt1),day(dt1))
    end
end
=#

# issue https://github.com/Alexander-Barth/NCDatasets.jl/issues/192
# Allow missing in dates

@test isequal(
    timedecode(DateTimeProlepticGregorian,[0,missing], "seconds since 2000-01-01 00:00:00"),
    [DateTimeProlepticGregorian(2000,1,1), missing]
)


@test isequal(
    timedecode([0,missing], "seconds since 2000-01-01 00:00:00", "proleptic_gregorian"),
    [DateTime(2000,1,1), missing]
)

@test isequal(
    timedecode(DateTime,[0,missing], "seconds since 2000-01-01 00:00:00"),
    [DateTime(2000,1,1), missing]
)

@test isequal(
    timeencode([DateTime(2000,1,1), missing], "seconds since 2000-01-01 00:00:00", "proleptic_gregorian"),
    [0.0,missing]
)

@test timeencode(DateTime(2000,1,2), "days since 2000-01-01 00:00:00") == 1


@test_logs (:warn,r".*cannot.*") @test_throws InexactError convert(DateTime,DateTimeStandard(2000,1,1,0,0,0,0,1,units = :microsecond))



# issue #27

# the leap day: 29 Feburary -4717 in proleptic Julian calendar
# https://web.archive.org/web/20231211220247/https://tondering.dk/claus/cal/chrmisc.php
Z = -2401403
T = DateTimeJulian
RYMD = Reference.datetuple_ymd(T,Z)
MYMD = CFTime.datetuple_ymd(T,Z)
@test RYMD == MYMD

Z2 = CFTime.datenum(T,MYMD...)
@test Z == Z2

@testset "zero" begin
    @test zero(DateTimeAllLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeNoLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
end
