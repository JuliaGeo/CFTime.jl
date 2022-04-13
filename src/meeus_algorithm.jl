module _Meeus

import ..DATENUM_OFFSET
import ..GREGORIAN_CALENDAR
import ..DN_GREGORIAN_CALENDAR


"""
    dn = datenum_gregjulian(year,month,day,gregorian::Bool)

Days since 1858-11-17 according to the Gregorian (`gregorian` is `true`) or
Julian Calendar (`gregorian` is `false`) based on the Algorithm of
Jean Meeus [1].

The year -1, correspond to 1 BC. The year 0 does not exist in the
Gregorian or Julian Calendar.

[1] Meeus, Jean (1998) Astronomical Algorithms (2nd Edition).
Willmann-Bell,  Virginia. p. 63
"""
function datenum_gregjulian(year,month,day,gregorian::Bool)
    # turn year equal to -1 (1 BC) into year = 0
    if year < 0
        year = year+1
    end

    if gregorian
        # bring year in range of 1601 to 2000
        ncycles = (2000 - year) ÷ 400
        year = year + 400 * ncycles
        # 146_097 = 365.2425 * 400
        return datenum_ac(year,month,day,gregorian) - ncycles*146_097
    else
        return datenum_ac(year,month,day,gregorian)
    end

end


# Meeus, Jean (1998) Astronomical Algorithms (2nd Edition). Willmann-Bell,  Virginia. p. 63
# However, the algorithm does not work for -100:03:01 and before in
# the proleptic Gregorian Calendar

function datenum_ac(year,month,day,gregorian::Bool)

    if month <= 2
        # if the date is January or February, it is considered
        # the 13rth or 14th month of the preceeding year
        year = year - 1
        month = month + 12
    end

    B =
        if gregorian
            A = year ÷ 100
            2 - A + A ÷ 4
        else
            0
        end

    # benchmark shows that it is 40% faster replacing
    # trunc(Int64,365.25 * (year + 4716))
    # by
    # (1461 * (year + 4716)) ÷ 4
    #
    # and other floating point divisions

    # Z is the Julian Day plus 0.5
    # 1461/4 is 365.25
    # 153/5 is 30.6

    # why 153/5 (or 30.6001 ?)
    # month+1 varies between 4 (March), 5 (April), .. 14 (December),
    # 15 (January), 16 (February)

    # cm = 153 * (4:16) ÷ 5; cm[2:end]-cm[1:end-1]
    #
    # length of each month
    # --------------------
    # 31  March
    # 30  April
    # 31  May
    # 30  June
    # 31  July
    # 31  August
    # 30  September
    # 31  October
    # 30  November
    # 31  December
    # 31  January
    # 30  February (wrong, but not used, since it is the last month)

    Z = (1461 * (year + 4716)) ÷ 4 + (153 * (month+1)) ÷ 5 + day + B - 2401525
    # Modified Julan Day
    return Z + DATENUM_OFFSET
end



"""
    year, month, day = datetuple_gregjulian(Z::Integer,gregorian::Bool)

Compute year, month and day from Z which is the Modified Julian Day
for the Gregorian (true) or Julian (false) calendar.

For example:
Z = 0 for the 1858 November 17 00:00:00

Algorithm:

Meeus, Jean (1998) Astronomical Algorithms (2nd Edition). Willmann-Bell,
Virginia. p. 63
"""
function datetuple_gregjulian(Z0::T,gregorian::Bool) where T

    # promote to at least Int64
    Z = promote_type(T, Int64)(Z0)

    # Z is Julian Day plus 0.5
    Z = Z + 2_400_001 - DATENUM_OFFSET

    A =
        if gregorian
            # 1867216.25 - 0.5 corresponds to the date 400-02-29T18:00:00
            # lets magic happen
            α = trunc(Int64, (Z - 1867_216.25)/36524.25)
            α = floor(Int64, (Z - 1867_216.25)/36524.25)
           @show Z
 #           @show (Z - 1867_216.25)/36524.25
            # 146_097 = 365.2425 * 400
            # α increases by 1 every century
            #α = (4*Z - 7468865) ÷ 146097
            if α < 0
#                α += 1
                        end
#            @show α
            Z + 1 + α - (α ÷ 4)
        else
            Z
        end

    # even more magic...
    B = A + 1524
    #C = trunc(Int64, (B - 122.1) / 365.25)
    C = (100*B - 12210) ÷ 36525
    #D = trunc(Int64, 365.25 * C)
    # 1461 = 3*365 + 366
    D = 1461 * C ÷ 4
    #E = trunc(Int64, (B-D)/30.6001)
    E = (10000 * (B-D)) ÷ 306001

    #day = B - D - trunc(Int64,30.6001 * E)
    day = B - D - (306001 * E) ÷ 10000

    month = (E < 14 ? E-1 : E-13)
    y = (month > 2 ? C - 4716 : C - 4715)

    # turn year 0 into year -1 (1 BC)
    if y <= 0
        y = y-1
    end
    return y,month,day
end

datetuple_prolepticgregorian(Z) = datetuple_gregjulian(Z,true)
datetuple_julian(Z) = datetuple_gregjulian(Z,false)
datetuple_standard(Z) = datetuple_gregjulian(Z,Z >= DN_GREGORIAN_CALENDAR)


datenum_prolepticgregorian(y,m,d) = datenum_gregjulian(y,m,d,true)
datenum_julian(y,m,d) = datenum_gregjulian(y,m,d,false)
datenum_standard(y,m,d) = datenum_gregjulian(y,m,d,(y,m,d) >= GREGORIAN_CALENDAR)

end
