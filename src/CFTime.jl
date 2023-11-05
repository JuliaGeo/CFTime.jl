"""
`CFTime` encodes and decodes time units conforming to the Climate and Forecasting (CF) netCDF conventions.
For example:

```julia
using CFTime, Dates
# Decoding "360 day" calendar
dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00",DateTime360Day)
# Encoding
CFTime.timeencode(dt,"days since 2000-01-01 00:00:00",DateTime360Day)
```
The following types are supported `DateTime`,
`DateTimeStandard`, `DateTimeJulian`, `DateTimeProlepticGregorian`
`DateTimeAllLeap`, `DateTimeNoLeap` and `DateTime360Day`
"""
module CFTime

using Printf
using Dates
import Dates: UTInstant, Millisecond
import Dates: year,  month,  day, hour, minute, second, millisecond
import Dates: daysinmonth, daysinyear, yearmonthday, yearmonth
import Dates: monthday, len, dayofyear, firstdayofyear

import Base: +, -, isless, string, show, convert, reinterpret

# solar year in ms (the interval between 2 successive passages of the sun
# through vernal equinox)
const SOLAR_YEAR = round(Int64,365.242198781 * 24*60*60*1000)

const DEFAULT_TIME_UNITS = "days since 1900-01-01 00:00:00"

# Introduction of the Gregorian Calendar 1582-10-15
const GREGORIAN_CALENDAR = (1582,10,15)

# Time offset in days for the time origin
# if DATENUM_OFFSET = 0, then datenum_gregjulian
# corresponds to  Modified Julian Days (MJD).
# MJD is the number of days since midnight on 1858-11-17)

#const DATENUM_OFFSET = 2_400_000.5 # for Julian Days
const DATENUM_OFFSET = 0 # for Modified Julian Days

# Introduction of the Gregorian Calendar 1582-10-15
# expressed in MJD (if DATENUM_OFFSET = 0)

const DN_GREGORIAN_CALENDAR = -100840 + DATENUM_OFFSET

# DateTime(UTInstant{Millisecond}(Dates.Millisecond(0)))
# returns 0000-12-31T00:00:00
# 678576 is the output of datenum_prolepticgregorian(-1,12,31)

const DATETIME_OFFSET = Dates.Millisecond(678576 * (24*60*60*Int64(1000)))

include("types.jl")


@inline isleap(::Type{DateTimeAllLeap},year,has_year_zero) = true
@inline isleap(::Type{DateTimeNoLeap},year,has_year_zero) = false

@inline function isleap(::Type{DateTimeProlepticGregorian},year,has_year_zero)
    if (year < 0) && !has_year_zero
        year = year + 1
    end
    return (year % 400 == 0) || ((year % 4 == 0) && (year % 100 !== 0))
end

@inline function isleap(::Type{DateTimeJulian},year,has_year_zero)
    if (year < 0) && !has_year_zero
        year = year + 1
    end
    return year % 4 == 0
end


@inline _hasyear0(::Type{T}) where T = false

include("meeus_algorithm.jl")

"""
    days,h,mi,s,ms = timetuplefrac(time::Number)

Return the number of whole days, hours (`h`), minutes (`mi`), seconds (`s`) and
millisecods (`ms`) from `time` expressed in milliseconds.
"""
function timetuplefrac(time::Number)
    # time can be negative, use fld instead of ÷
    days = fld(Int64(time), (24*60*60*1000))
    ms = Int64(time) - days * (24*60*60*1000)

    h = ms ÷ (60*60*1000)
    ms = ms - h * (60*60*1000)

    mi = ms ÷ (60*1000)
    ms = ms - mi * (60*1000)

    s = ms ÷ 1000
    ms = ms - s * 1000
    return (days,h,mi,s,ms)
end

function datenumfrac(days,h,mi,s,ms)
    ms = 60*60*1000 * h +  60*1000 * mi + 1000*s + ms
    return (24*60*60*1000) * Int64(days) + ms
end

function datenum(::Type{T}, y, m, d) where T <: AbstractCFDateTime
    cm = _cum_month_length(T)
    # turn year equal to -1 (1 BC) into year = 0
    if (y < 0) && !_hasyear0(T)
        y = y+1
    end

    if m < 1 || m > 12
        error("invalid month $(m)")
    end

    if d < 1 || d > (cm[m+1] - cm[m])
        error("invalid day $(d) in $(@sprintf("%04d-%02d-%02d",y,m,d))")
    end

    return cm[end] * (y-1) + cm[m] + (d-1)
end

# Calendar with regular month-length

function findmonth(cm,t2)
    mo = length(cm)
    while cm[mo] > t2
        mo -= 1
    end
    return mo
end

function datetuple_ymd(::Type{T},timed_::Number) where T <: AbstractCFDateTime
    cm = _cum_month_length(T)
    y = fld(Int64(timed_), cm[end])
    t2 = Int64(timed_) - cm[end]*y

    # find month
    mo = findmonth(cm,t2)
    d = t2 - cm[mo]

    # day and year start at 1 (not zero)
    d = d+1
    y = y+1

    if (y <= 0) && !_hasyear0(T)
        y = y-1
    end

    return (y,mo,d)
end

@inline _cum_month_length(::Type{DateTimeAllLeap}) =
    (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366)

@inline _cum_month_length(::Type{DateTimeNoLeap}) =
    (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365)

@inline _cum_month_length(::Type{DateTime360Day}) =
    (0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360)


function validargs(::Type{T},arg...) where T <: AbstractCFDateTime
    return nothing
end


for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]
    @eval begin
        """
    $($CFDateTime)(y, [m, d, h, mi, s, ms]) -> $($CFDateTime)

Construct a `$($CFDateTime)` type by year (`y`), month (`m`, default 1),
day (`d`, default 1), hour (`h`, default 0), minute (`mi`, default 0),
second (`s`, default 0), millisecond (`ms`, default 0).
All arguments must be convertible to `Int64`.
`$($CFDateTime)` is a subtype of `AbstractCFDateTime`.

The netCDF CF calendars are defined in [the CF Standard](http://cfconventions.org/cf-conventions/cf-conventions.html#calendar).
This type implements the calendar defined as "$($calendar)".
        """
        function $CFDateTime(y::Int64, m::Int64=1, d::Int64=1,
                             h::Int64=0, mi::Int64=0, s::Int64=0, ms::Int64=0)

            days = datenum($CFDateTime,y,m,d)
            totalms = datenumfrac(days,h,mi,s,ms)
            return $CFDateTime(UTInstant(Millisecond(totalms)))
        end

        # Fallback constructors
        $CFDateTime(y::Number, m=1, d=1, h=0, mi=0, s=0, ms=0) = $CFDateTime(
            Int64(y), Int64(m), Int64(d), Int64(h), Int64(mi), Int64(s),
            Int64(ms))

        if VERSION >= v"1.3-"
            function $CFDateTime(y, m, d, h, mi, s, ms, ampm)
                @assert ampm == Dates.TWENTYFOURHOUR
                return $CFDateTime(y, m, d, h, mi, s, ms)
            end
        end
        """
    $($CFDateTime)(dt::AbstractString, format::AbstractString; locale="english") -> $($CFDateTime)

Construct a $($CFDateTime) by parsing the `dt` date time string following the
pattern given in the `format` string.

!!! note
    This function is experimental and might
    be removed in the future. It relies on some internal function of `Dates` for
    parsing the `format`.
"""
        function $CFDateTime(dt::AbstractString, format::AbstractString; locale="english")
            return parse($CFDateTime, dt, DateFormat(format, locale))
        end

        $CFDateTime(dt::AbstractString, format::DateFormat) =
            parse($CFDateTime, dt, format)

    end
end

function datetuple(dt::T) where T <: AbstractCFDateTime
    time = Dates.value(dt.instant.periods)
    days,h,mi,s,ms = timetuplefrac(time)
    y, m, d = datetuple_ymd(T,days)
    return y, m, d, h, mi, s, ms
end



function string(dt::T)  where T <: AbstractCFDateTime
    y,mo,d,h,mi,s,ms = datetuple(dt)
    return @sprintf("%04d-%02d-%02dT%02d:%02d:%02d",y,mo,d,h,mi,s)
end

function show(io::IO,dt::T)  where T <: AbstractCFDateTime
    write(io, string(typeof(dt)), "(",string(dt),")")
end

function +(dt::T,Δ::Dates.Year)  where T <: AbstractCFDateTime
    y,mo,d,h,mi,s,ms = datetuple(dt)
    return T(y+Dates.value(Δ), mo, d, h, mi, s, ms)
end

function +(dt::T,Δ::Dates.Month)  where T <: AbstractCFDateTime
    y,mo,d,h,mi,s,ms = datetuple(dt)
    mo = mo + Dates.value(Δ)
    mo2 = mod(mo - 1, 12) + 1
    y = y + (mo-mo2) ÷ 12
    return T(y, mo2, d,h, mi, s, ms)
end

+(dt::T,Δ::RegTime)  where T <: AbstractCFDateTime = T(UTInstant(dt.instant.periods + Dates.Millisecond(Δ)))

-(dt1::T,dt2::T)  where T <: AbstractCFDateTime = dt1.instant.periods - dt2.instant.periods

isless(dt1::T,dt2::T) where T <: AbstractCFDateTime = dt1.instant.periods < dt2.instant.periods


-(dt1::Union{DateTimeStandard,DateTimeJulian,DateTimeProlepticGregorian},
  dt2::DateTime) = DateTime(dt1) - DateTime(dt2)

-(dt1::Union{DateTimeStandard,DateTimeJulian,DateTimeProlepticGregorian},
  dt2::Union{DateTimeStandard,DateTimeJulian,DateTimeProlepticGregorian}) = DateTime(dt1) - DateTime(dt2)

-(dt1::DateTime,
  dt2::Union{DateTimeStandard,DateTimeJulian,DateTimeProlepticGregorian}) = DateTime(dt1) - DateTime(dt2)



"""
    dt2 = reinterpret(::Type{T}, dt)

Convert a variable `dt` of type `DateTime`, `DateTimeStandard`, `DateTimeJulian`,
`DateTimeProlepticGregorian`, `DateTimeAllLeap`, `DateTimeNoLeap` or
`DateTime360Day` into the date time type `T` using the same values for
year, month, day, minute, second and millisecond.
The conversion might fail if a particular date does not exist in the
target calendar.
"""
function reinterpret(::Type{T1}, dt::T2) where T1 <: Union{AbstractCFDateTime,DateTime} where T2 <: Union{AbstractCFDateTime,DateTime}
   return T1(
       Dates.year(dt),Dates.month(dt),Dates.day(dt),
       Dates.hour(dt),Dates.minute(dt),Dates.second(dt),
       Dates.millisecond(dt))
end

"""
    dt2 = convert(::Type{T}, dt)

Convert a DateTime of type `DateTimeStandard`, `DateTimeProlepticGregorian`,
`DateTimeJulian` or `DateTime` into the type `T` which can also be either
`DateTimeStandard`, `DateTimeProlepticGregorian`, `DateTimeJulian` or `DateTime`.

Conversion is done such that duration (difference of DateTime types) are
preserved. For dates on and after 1582-10-15, the year, month and days are the same for
the types `DateTimeStandard`, `DateTimeProlepticGregorian` and `DateTime`.

For dates before 1582-10-15, the year, month and days are the same for
the types `DateTimeStandard` and `DateTimeJulian`.
"""
function convert(::Type{T1}, dt::T2) where T1 <: Union{DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian} where T2 <: Union{DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian}
    return T1(dt.instant)
end

function convert(::Type{DateTime}, dt::T2) where T2 <: Union{DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian}
    DateTime(UTInstant{Millisecond}(dt.instant.periods + DATETIME_OFFSET))
end

function convert(::Type{T1}, dt::DateTime) where T1 <: Union{DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian}
    T1(UTInstant{Millisecond}(dt.instant.periods - DATETIME_OFFSET))
end


Dates.year(dt::AbstractCFDateTime) = datetuple(dt)[1]
Dates.month(dt::AbstractCFDateTime) = datetuple(dt)[2]
Dates.day(dt::AbstractCFDateTime) = datetuple(dt)[3]
Dates.hour(dt::AbstractCFDateTime)   = datetuple(dt)[4]
Dates.minute(dt::AbstractCFDateTime) = datetuple(dt)[5]
Dates.second(dt::AbstractCFDateTime) = datetuple(dt)[6]
Dates.millisecond(dt::AbstractCFDateTime) = datetuple(dt)[7]



for func in (:year, :month, :day, :hour, :minute, :second, :millisecond)
    name = string(func)
    @eval begin
        @doc """
            Dates.$($name)(dt::AbstractCFDateTime) -> Int64

        Extract the $($name)-part of a `AbstractCFDateTime` as an `Int64`.
        """ $func(dt::AbstractCFDateTime)
    end
end


-(dt::AbstractCFDateTime,Δ) = dt + (-Δ)

function datetime_tuple(str)
    str = replace(str,"T" => " ")

    # remove Z time zone indicator
    # all times are assumed UTC anyway
    if endswith(str,"Z")
        str = str[1:end-1]
    end


    negativeyear = str[1] == '-'
    if negativeyear
        str = str[2:end]
    end

    y,m,d,h,mi,s,ms =
        if occursin(" ",str)
            datestr,timestr = split(str,' ')
            y,m,d = parse.(Int64,split(datestr,'-'))

            timestr,tz = if occursin("+",timestr)
              ts,tz = split(timestr,"+")
              ts,tz
            elseif occursin("-",timestr)
              ts,tz = split(timestr,"-")
              ts,string("-",tz)
            else
              timestr, "00:00"
            end
            if !all(iszero(parse.(Int,split(tz,":"))))
              @warn "Time zones are currently not supported by CFTime. Ignoring Time zone information: $(tz)"
            end

            time_split = split(timestr,':')
            h_str, mi_str, s_str =
                if length(time_split) == 2
                    time_split[1], time_split[2], "00"
                else
                    time_split
                end


            h = parse(Int64,h_str)
            mi = parse(Int64,mi_str)
            s,ms =
                if occursin('.',s_str)
                    # seconds contain a decimal point, e.g. 00:00:00.0
                    secfrac = parse(Float64,s_str)
                    s = floor(Int64,secfrac)
                    ms = round(Int64,1000*(secfrac - s))
                    s,ms
                else
                    (parse(Int64,s_str),Int64(0))
                end

            (y,m,d,h,mi,s,ms)
        else
            y,m,d = parse.(Int64,split(str,'-'))
            (y,m,d,Int64(0),Int64(0),Int64(0),Int64(0))
        end

    if negativeyear
        y = -y
    end

    return (y,m,d,h,mi,s,ms)
end



function parseDT(::Type{DT},str) where DT <: Union{DateTime,AbstractCFDateTime}
    return DT(datetime_tuple(str)...)
end

function parseDT(::Type{Tuple},str)
    return datetime_tuple(str)
end

function timeunits(::Type{DT},units) where DT
    tunit_mixedcase,starttime = strip.(split(units," since "))
    tunit = lowercase(tunit_mixedcase)

    t0 = parseDT(DT,starttime)

    # make sure that plength is 64-bit on 32-bit platforms
    plength =
        if (tunit == "years") || (tunit == "year")
            SOLAR_YEAR
        elseif (tunit == "months") || (tunit == "month")
            SOLAR_YEAR ÷ 12
        elseif (tunit == "days") || (tunit == "day")
            24*60*60*Int64(1000)
        elseif (tunit == "hours") || (tunit == "hour")
            60*60*Int64(1000)
        elseif (tunit == "minutes") || (tunit == "minute")
            60*Int64(1000)
        elseif (tunit == "seconds") || (tunit == "second")
            Int64(1000)
        elseif (tunit == "milliseconds") || (tunit == "millisecond")
            Int64(1)
        else
            error("unknown units \"$(tunit)\"")
        end

    return t0,plength
end


function timetype(calendar = "standard")
    DT =
        if (calendar == "standard") || (calendar == "gregorian")
            DateTimeStandard
        elseif calendar == "proleptic_gregorian"
            DateTimeProlepticGregorian
        elseif calendar == "julian"
            DateTimeJulian
        elseif (calendar == "noleap") || (calendar == "365_day")
            DateTimeNoLeap
        elseif (calendar == "all_leap") || (calendar == "366_day")
            DateTimeAllLeap
        elseif calendar == "360_day"
            DateTime360Day
        else
            error("Unsupported calendar: $(calendar)")
        end

    return DT
end

timetype(dt::Type{<:AbstractCFDateTime}) = dt
timetype(dt::Type{DateTime}) = dt

"""
    t0,plength = timeunits(units,calendar = "standard")

Parse time units (e.g. "days since 2000-01-01 00:00:00") and returns the start
time `t0` and the scaling factor `plength` in milliseconds.
"""
function timeunits(units, calendar = "standard")
    DT = timetype(calendar)
    return timeunits(DT,units)
end

function timedecode(::Type{DT},data::AbstractArray{Float32,N},units) where {DT,N}
    # convert to Float64
    return timedecode(DT,Float64.(data),units)
end

_convert(x,t0,plength) = t0 + Dates.Millisecond(round(Int64,plength * x))
_convert(x::Missing,t0,plength) = missing

function timedecode(::Type{DT},data,units) where DT
    t0,plength = timeunits(DT,units)
    return _convert.(data,t0,plength)
end


"""
    dt = timedecode(data,units,calendar = "standard", prefer_datetime = true)

Decode the time information in data as given by the units `units` according to
the specified calendar. Valid values for `calendar` are
`"standard"`, `"gregorian"`, `"proleptic_gregorian"`, `"julian"`, `"noleap"`, `"365_day"`,
`"all_leap"`, `"366_day"` and `"360_day"`.

If `prefer_datetime` is `true` (default), dates are
converted to the `DateTime` type (for the calendars
"standard", "gregorian", "proleptic_gregorian" and "julian"). Such conversion is
not possible for the other calendars.

| Calendar            | Type (prefer_datetime=true) | Type (prefer_datetime=false) |
| ------------------- | --------------------------- | ---------------------------- |
| `standard`, `gregorian` | `DateTime`                    | `DateTimeStandard`             |
| `proleptic_gregorian` | `DateTime`                    | `DateTimeProlepticGregorian`   |
| `julian`              | `DateTime`                    | `DateTimeJulian`               |
| `noleap`, `365_day`     | `DateTimeNoLeap`              | `DateTimeNoLeap`               |
| `all_leap`, `366_day`   | `DateTimeAllLeap`             | `DateTimeAllLeap`              |
| `360_day`             | `DateTime360Day`              | `DateTime360Day`               |

## Example:

```julia
using CFTime, Dates
# standard calendar
dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00")
# 4-element Array{Dates.DateTime,1}:
#  2000-01-01T00:00:00
#  2000-01-02T00:00:00
#  2000-01-03T00:00:00
#  2000-01-04T00:00:00

dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00","360_day")
# 4-element Array{DateTime360Day,1}:
#  DateTime360Day(2000-01-01T00:00:00)
#  DateTime360Day(2000-01-02T00:00:00)
#  DateTime360Day(2000-01-03T00:00:00)
#  DateTime360Day(2000-01-04T00:00:00)
```

"""
function timedecode(data,units,calendar = "standard"; prefer_datetime = true)
    DT = timetype(calendar)
    dt = timedecode(DT,data,units)

    if prefer_datetime &&
        (DT in [DateTimeStandard,DateTimeProlepticGregorian,DateTimeJulian])

        datetime_convert(dt) = convert(DateTime,dt)
        datetime_convert(dt::Missing) = missing
        return datetime_convert.(dt)
    else
        return dt
    end
end


"""
    data = timeencode(dt,units,calendar = "standard")

Convert a vector or array of `DateTime` (or `DateTimeStandard`,
`DateTimeProlepticGregorian`, `DateTimeJulian`, `DateTimeNoLeap`,
`DateTimeAllLeap`, `DateTime360Day`) according to
the specified units (e.g. `"days since 2000-01-01 00:00:00"`) using the calendar
`calendar`.  Valid values for calendar are:
`"standard"`, `"gregorian"`, `"proleptic_gregorian"`, `"julian"`, `"noleap"`, `"365_day"`,
`"all_leap"`, `"366_day"`, `"360_day"`.
"""
function timeencode(data::AbstractArray{DT,N},units,
                    calendar = "standard") where N where DT <: Union{DateTime,AbstractCFDateTime,Union{DateTime,AbstractCFDateTime,Missing}}

    DT2 = timetype(calendar)
    t0,plength = timeunits(DT2,units)

    function encode(dt)
        if ismissing(dt)
            return missing
        end

        tmp =
            try
                convert.(DT2,dt)
            catch
                error("It is not possible to convert from $(DT) to $(DT2)")
            end

        return Dates.value(tmp - t0) / plength
    end
    return encode.(data)
end


function timeencode(data::DT,units,
                    calendar = "standard") where DT <: Union{DateTime,AbstractCFDateTime}
    return timeencode([data],units,calendar)[1]
end


# do not transform data is not a vector of DateTime
# unused, should be removed
timeencode(data,units,calendar = "standard") = data

export timeencode, timedecode, datetuple


# utility functions

"""
    monthlength = daysinmonth(::Type{DT},y,m)

Returns the number of days in a month for the year `y` and the month `m`
according to the calendar given by the type `DT`.

Example
```julia-repl
julia> daysinmonth(DateTimeAllLeap,2001,2)
29
```

"""
function daysinmonth(::Type{DT},y,m) where DT <: Union{DateTime, AbstractCFDateTime}
    t = DT(y,m,1)
    return Dates.value((t + Dates.Month(1)) - t) ÷ (24*60*60*1000)
end

"""
    monthlength = daysinmonth(t)

Returns the number of days in a month containing the date `t`

Example
```julia-repl
julia> daysinmonth(DateTimeAllLeap(2001,2,1))
29
```
"""
function daysinmonth(t::DT) where DT <: Union{DateTime, AbstractCFDateTime}
    return daysinmonth(DT,Dates.year(t),Dates.month(t))
end

"""
    yearlength = daysinyear(::Type{DT},y)

Returns the number of days in a year for the year `y`
according to the calendar given by the type `DT`.

Example
```julia-repl
julia> daysinyear(DateTimeAllLeap,2001,2)
366
```

"""
function daysinyear(::Type{DT},y) where DT <: Union{DateTime, AbstractCFDateTime}
    t = DT(y,1,1)
    return Dates.value((t + Dates.Year(1)) - t) ÷ (24*60*60*1000)
end

"""
    yearlength = daysinyear(t)

Returns the number of days in a year containing the date `t`

Example
```julia-repl
julia> daysinyear(DateTimeAllLeap(2001,2,1))
366
```
"""
function daysinyear(t::DT) where DT <: Union{DateTime, AbstractCFDateTime}
    return daysinyear(DT,Dates.year(t))
end

"""
    yearmonthday(dt::AbstractCFDateTime) -> (Int64, Int64, Int64)

Simultaneously return the year, month and day parts of `dt`.
"""
yearmonthday(dt::AbstractCFDateTime) = (Dates.year(dt),Dates.month(dt),Dates.day(dt))

"""
    yearmonth(dt::AbstractCFDateTime) -> (Int64, Int64)

Simultaneously return the year and month parts of `dt`.
"""
yearmonth(dt::AbstractCFDateTime) = (Dates.year(dt),Dates.month(dt))

"""
    monthday(dt::AbstractCFDateTime) -> (Int64, Int64)

Simultaneously return the month and day parts of `dt`.
"""
monthday(dt::AbstractCFDateTime) = (Dates.month(dt),Dates.day(dt))


"""
    firstdayofyear(dt::AbstractCFDateTime) -> Int

Return the first day of the year including the date `dt`
"""
firstdayofyear(dt::T) where T <: AbstractCFDateTime = T(Dates.year(dt),1,1,0,0,0)


"""
    dayofyear(dt::AbstractCFDateTime) -> Int

Return the day of the year for dt with January 1st being day 1.
"""
function dayofyear(dt::AbstractCFDateTime)
    t0 = firstdayofyear(dt)
    return Dates.value(dt - t0) ÷ (24*60*60*1000) + 1
end

function Dates.len(first::T, last::T, step::DT) where T <: AbstractCFDateTime where
    DT <: Union{Dates.Day,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}
    return Dates.value(last-first) ÷ Dates.value(Dates.Millisecond(step))
end

function Dates.len(first::T, last::T, step) where T <: AbstractCFDateTime
    if Dates.value(step) == 0
        error("the step should not be zero")
    end
    len = 0
    next = first+step
    while next <= last
        next = next+step
        len = len+1
    end
    return len
end

export daysinmonth,
    daysinyear,
    yearmonthday,
    yearmonth,
    monthday,
    firstdayofyear,
    dayofyear,
    DateTimeStandard,
    DateTimeJulian,
    DateTimeProlepticGregorian,
    DateTimeAllLeap,
    DateTimeNoLeap,
    DateTime360Day,
    AbstractCFDateTime


function __init__()
    for CFDateTime in [DateTimeStandard,
                       DateTimeJulian,
                       DateTimeProlepticGregorian,
                       DateTimeAllLeap,
                       DateTimeNoLeap,
                       DateTime360Day]
        Dates.CONVERSION_TRANSLATIONS[CFDateTime] = Dates.CONVERSION_TRANSLATIONS[DateTime]
    end
end

end

#  LocalWords:  CFTime netCDF julia dt timedecode DateTime timeencode
#  LocalWords:  DateTimeStandard DateTimeJulian DateTimeAllLeap MJD
#  LocalWords:  DateTimeProlepticGregorian DateTimeNoLeap DATENUM jl
#  LocalWords:  datenum gregjulian const UTInstant prolepticgregorian
#  LocalWords:  meeus timetuplefrac millisecods fld julian allleap dT
#  LocalWords:  noleap CFDateTime subtype AbstractCFDateTime english
#  LocalWords:  tz plength tunit gregorian proleptic timeunits repl
#  LocalWords:  datetime monthlength daysinmonth yearlength yearmonth
#  LocalWords:  daysinyear yearmonthday monthday firstdayofyear
#  LocalWords:  dayofyear
