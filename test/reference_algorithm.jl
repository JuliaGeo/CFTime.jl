module Reference

import CFTime: isleap, DateTimeJulian, DateTimeProlepticGregorian

# Adapted
# from https://github.com/Unidata/cftime/blob/dc75368cd02bbcd1352dbecfef10404a58683f94/src/cftime/_cftime.pyx
# Licence MIT
# by Jeff Whitaker (https://github.com/jswhit)

@inline function month_lengths(::Type{T}, year::Integer, hasyear0) where T
    if isleap(T, year, hasyear0)
        return (31,29,31,30,31,30,31,31,30,31,30,31)
    else
        return (31,28,31,30,31,30,31,31,30,31,30,31)
    end
end


@inline function datetuple_ymd(::Type{T}, delta_days, julian_gregorian_mixed, hasyear0) where T
    year = 1858
    month = 11
    day = 17

    month_length = month_lengths(T, year, hasyear0)

    n_invalid_dates =
        if julian_gregorian_mixed
            10
        else
            0
        end

    @inbounds while delta_days < 0
        if (year == 1582) && (month == 10) && (day > 14) && (day + delta_days < 15)
            delta_days -= n_invalid_dates    # skip over invalid dates
        end

        if day + delta_days < 1
            delta_days += day
            # decrement month
            month -= 1
            if month < 1
                month = 12
                year -= 1
                if (year == 0) && !hasyear0
                    year = -1
                end
                month_length = month_lengths(T, year, hasyear0)
            end

            day = month_length[month]
        else
            day += delta_days
            delta_days = 0
        end
    end

    @inbounds while delta_days > 0
        if (year == 1582) && (month == 10) && (day < 5) && (day + delta_days > 4)
            delta_days += n_invalid_dates    # skip over invalid dates
        end

        if day + delta_days > month_length[month]
            delta_days -= month_length[month] - (day - 1)
            # increment month
            month += 1
            if month > 12
                month = 1
                year += 1
                if (year == 0) && !hasyear0
                    year = 1
                end
                month_length = month_lengths(T, year, hasyear0)
            end
            day = 1
        else
            day += delta_days
            delta_days = 0
        end
    end

    return year,month,day
end

function datetuple_ymd(::Type{DateTimeProlepticGregorian},Z)
    hasyear0 = true
    julian_gregorian_mixed = false
    return datetuple_ymd(DateTimeProlepticGregorian, Z, julian_gregorian_mixed, hasyear0)
end

end
