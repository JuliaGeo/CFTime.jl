using CFTime
using Test

include("reference_algorithm.jl")

function test_dates(::Type{T},YMD0,YMD1) where T
    nsuccess = 0
    fails = []

    # start day
    YMD = YMD0

    Z = CFTime.datenum(T,YMD...)


    has_year_zero = CFTime._hasyear0(T)
    julian_gregorian_mixed = T <: DateTimeStandard
    Δdays = 1

    while YMD != YMD1
        # next day using the reference algorithm
        YMD = Reference.add_timedelta_ymd(T, YMD, Δdays, julian_gregorian_mixed, has_year_zero)

        # next day using the adapted Meeus algorithm
        Z += Δdays
        MYMD = CFTime.datetuple_ymd(T,Z)

        if MYMD == YMD
            nsuccess += 1
        else
            push!(fails,Z)
        end

        # test round-trip
        Z2 = CFTime.datenum(T,MYMD...)

        if Z == Z2
            nsuccess += 1
        else
            push!(fails,Z)
        end

    end

    return (nsuccess,fails)
end

T = DateTimeStandard

YMD0 = (-1_000_000,1,1)
YMD1 = (1_000_000,1,1)

# quick test
YMD0 = (-100_000,1,1)

YMD1 = (100_000,12,31)


for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]
#for T in [DateTime360Day]

    global YMD1

    if T <: DateTime360Day
        YMD1 = (YMD1[1:2]...,30)
    end

    nsuccess,fails = @time test_dates(T,YMD0,YMD1)


    println(T," success: ",nsuccess)
    println(T," fails: ",length(fails))

    if length(fails) > 0
        println.(fails);
    end
end
