"""
    dn = datenum_gregjulian(year,month,day,gregorian::Bool)

Days since 1858-11-17 according to the Gregorian (`gregorian` is `true`) or
Julian Calendar (`gregorian` is `false`) based on the Algorithm of
Jean Meeus [1] modified to handle dates prior to 100 BC.

The year -1, correspond to 1 BC. The year 0 does not exist in the
Gregorian or Julian Calendar.

[1] Meeus, Jean (1998) Astronomical Algorithms (2nd Edition).
Willmann-Bell,  Virginia. p. 63
"""
function datenum_gregjulian(year,month,day,gregorian::Bool,has_year_zero = false)
    # turn year equal to -1 (1 BC) into year = 0
    if (year < 0) && !has_year_zero
        year = year+1
    end

    if month <= 2
        # if the date is January or February, it is considered
        # the 13rth or 14th month of the preceeding year
        year = year - 1
        month = month + 12
    end

    B =
        if gregorian
            A = fld(year, 100)
            2 - A + fld(A, 4)
        else
            0
        end

    #
    # benchmark shows that integer division is 40% faster than floating point division
    # flowing by truncation

    # julia> yyear = 2024
    # julia> @btime trunc(Int64,365.25 * ($yyear + 4716))
    #   2.881 ns (0 allocations: 0 bytes)
    # 2461785

    # julia> @btime fld(1461 * ($yyear + 4716), 4)
    #   1.929 ns (0 allocations: 0 bytes)
    # 2461785
    #
    #  11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz

    # Z is the Julian Day plus 0.5
    # 1461/4 is 365.25
    # 153/5 is 30.6

    # why 153/5 (or 30.6001 ?)
    # month+1 varies between 4 (March), 5 (April), .. 14 (December),
    # 15 (January), 16 (February)
    # The 5 months March - July = 153 days
    # The 5 months August - December = 153 days

    # cm = 153 * (4:16) ÷ 5; cm[2:end]-cm[1:end-1]
    #
    #  E length  month
    # ---------------------
    #  4   31    March
    #  5   30    April
    #  6   31    May
    #  7   30    June
    #  8   31    July
    #
    #  9   31    August
    # 10   30    September
    # 11   31    October
    # 12   30    November
    # 13   31    December
    #
    # 14   31    January
    # 15   30    February (wrong, but not used, since it is the last month)

    # 4 years in the Julian calendar = 4*365 + 1 = 1461 days
    Z = fld(1461 * (year + 4716), 4) + (153 * (month+1)) ÷ 5 + day + B - 2401525
    # Modified Julan Day
    return Z + DATENUM_OFFSET
end



"""
    year, month, day = datetuple_gregjulian(Z::Integer,gregorian::Bool)

Compute year, month and day from Z which is the Modified Julian Day
for the Gregorian (true) or Julian (false) calendar.
using the algorithm of Meeus (1998) modified to handle dates prior to 300 AC.

For example:
Z = 0 for the 1858 November 17 00:00:00

Algorithm:

Meeus, Jean (1998) Astronomical Algorithms (2nd Edition). Willmann-Bell,
Virginia. p. 63
"""
function datetuple_gregjulian(Z0::T,gregorian::Bool,has_year_zero = false) where T

    # promote to at least Int64
    Z = promote_type(T, Int64)(Z0)

    # Z is Julian Day plus 0.5
    Z = Z + (2_400_001 - DATENUM_OFFSET)

    A = Z

    if gregorian
        # 1867216.25 - 0.5 corresponds to the date 400-02-29T18:00:00
        # lets magic happen
        # 400 years = 146097 days = (400 * 365 + 100 - 4 + 1) days
        # α number of centuries since 400-02-29
        α = fld(4*Z - 7468865, 146097)

        # +α: add leap days for 1700, 1800, 1900, 2000, 2100,
        # -fld(α, 4): remove leap days for 2000, 2400, ... (already included)
        # so that Julian and Gregorian calendar coincide
        A += 1 + α - fld(α, 4)
    end

    B = A + 1524

    # 20 years = 5 * (4*365 + 1) = 7305 days in the Julian calendar
    C = fld(20*B - 2442, 7305)
    # 4 years = 4*365 + 1 = 1461 days
    D = fld(1461 * C, 4)
    # we use 306001/10000 = 30.6001 rather than 30.6 to avoid
    # a day 0, e.g. Feburary 0 instead of January 31
    E = fld(10000 * (B-D), 306001)

    day = B - D - fld(306001 * E, 10000)

    # shift to first month from March to January
    month = (E < 14 ? E-1 : E-13)
    y = (month > 2 ? C - 4716 : C - 4715)

    # turn year 0 into year -1 (1 BC)
    if (y <= 0) && !has_year_zero
        y = y-1
    end
    return y,month,day
end

datetuple_ymd(::Type{DateTimeProlepticGregorian},Z::Number) =
    datetuple_gregjulian(Z,true,_hasyear0(DateTimeProlepticGregorian))

datetuple_ymd(::Type{DateTimeJulian},Z::Number) =
    datetuple_gregjulian(Z,false,_hasyear0(DateTimeJulian))

datetuple_ymd(::Type{DateTimeStandard},Z::Number) =
    datetuple_gregjulian(Z,Z >= DN_GREGORIAN_CALENDAR,_hasyear0(DateTimeStandard))

datenum(::Type{DateTimeProlepticGregorian},y,m,d) =
    datenum_gregjulian(y,m,d,true,_hasyear0(DateTimeProlepticGregorian))

datenum(::Type{DateTimeJulian},y,m,d) =
    datenum_gregjulian(y,m,d,false,_hasyear0(DateTimeJulian))

datenum(::Type{DateTimeStandard},y,m,d) =
    datenum_gregjulian(y,m,d,(y,m,d) >= GREGORIAN_CALENDAR,_hasyear0(DateTimeStandard))


