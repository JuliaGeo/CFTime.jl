using CFTime

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


# conversion when substracting dates
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


@testset "zero" begin
    @test zero(DateTimeAllLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeNoLeap) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTimeJulian) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
    @test zero(DateTime360Day) == CFTime.Millisecond(0)
end

