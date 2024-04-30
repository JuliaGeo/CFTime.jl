# CFTime.jl

This package implements the calendar types from the [CF convention](http://cfconventions.org/Data/cf-conventions/cf-conventions-1.7/cf-conventions.html#calendar), namely:

* Mixed Gregorian/Julian calendar  (`DateTimeStandard`)
* Proleptic gregorian calendar (`DateTimeProlepticGregorian`)
* Gregorian calendar without leap years (all years are 365 days long) (`DateTimeNoLeap`)
* Gregorian calendar with only leap year (all years are 366 days long) (`DateTimeAllLeap`)
* A calendar with every year being 360 days long (divided into 30 day months) (`DateTime360Day`)
* Julian calendar (`DateTimeJulian`)

Note that time zones are not supported by `CFTime.jl`.


## Installation

Inside the Julia shell, you can download and install the package by issuing:

```julia
using Pkg
Pkg.add("CFTime")
```

### Latest development version

If you want to try the latest development version, you can do this with the following commands:

```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/JuliaGeo/CFTime.jl", rev="master"))
Pkg.build("CFTime")
```

## Types

```@docs
DateTimeStandard
DateTimeJulian
DateTimeProlepticGregorian
DateTimeAllLeap
DateTimeNoLeap
DateTime360Day
```

## Time encoding and decoding

```@docs
CFTime.timedecode
CFTime.timeencode
```

## Accessor Functions

```@docs
CFTime.year(dt::AbstractCFDateTime)
CFTime.month(dt::AbstractCFDateTime)
CFTime.day(dt::AbstractCFDateTime)
CFTime.hour(dt::AbstractCFDateTime)
CFTime.minute(dt::AbstractCFDateTime)
CFTime.second(dt::AbstractCFDateTime)
CFTime.millisecond(dt::AbstractCFDateTime)
CFTime.microsecond(dt::AbstractCFDateTime)
CFTime.nanosecond(dt::AbstractCFDateTime)
CFTime.picosecond(dt::AbstractCFDateTime)
CFTime.femtosecond(dt::AbstractCFDateTime)
CFTime.attosecond(dt::AbstractCFDateTime)
```

## Query Functions

```@docs
daysinmonth
daysinyear
yearmonthday
yearmonth
monthday
firstdayofyear
dayofyear
```

## Convertion Functions

```@docs
convert
reinterpret
```

## Arithmetic

Adding and subtracting time periods is supported:

```julia
DateTimeStandard(1582,10,4) + Dates.Day(1)
# returns DateTimeStandard(1582-10-15T00:00:00)
```

1582-10-15 is the adoption of the Gregorian Calendar.

Comparision operator can be used to check if a date is before or after another date.

```julia
DateTimeStandard(2000,01,01) < DateTimeStandard(2000,01,02)
# returns true
```

Time ranges can be constructed using a start date, end date and a time increment, for example: `DateTimeStandard(2000,1,1):Dates.Day(1):DateTimeStandard(2000,12,31)`


## Rounding

```julia
using CFTime: DateTimeStandard

dt = DateTimeStandard(24*60*60,"second since 2000-01-01")

floor(dt+Second(9),Second(10)) == dt
# output

true

ceil(dt+Second(9),Second(10)) == dt + Second(10)
# output

true

round(dt+Second(9),Second(10)) == dt + Second(10)
# output

true
```


Julia's `DateTime` records the time relative to a time orgin (January 1st, 1 BC or 0000-01-01 in ISO_8601) with a millisecond accuracy. Converting CFTime date time structures to
Julia's `DateTime` (using `convert(DateTime,dt)`) can trigger an inexact exception if the convertion cannot be done without loss of precision. One can use the `round` function in order to round to the nearest time represenatable by `DateTime`:

```julia
using CFTime: DateTimeStandard
using Dates: DateTime
dt = DateTimeStandard(24*60*60*1000*1000 + 123,"microsecond since 2000-01-01")
round(DateTime,dt)
# output

2000-01-02T00:00:00
```

## Internal API

For CFTime 0.1.3 and before all date-times are encoded using internally milliseconds since a fixed time origin and stored as an `Int64` similar to julia's `Dates.DateTime`.
However, this approach does not allow to encode time with a sub-millisecond precision allowed by the CF convention and supported by e.g. [numpy](https://numpy.org/doc/1.25/reference/arrays.datetime.html#datetime-units). While `numpy` allows attosecond precision, it can only encode a time span of ±9.2 around the date 00:00:00 UTC on 1 January 1970. In CFTime the time origin and the number containing the duration and the time precision are now encoded as two additional type parameters.

When wrapping a CFTime date-time type, it is recommended for performance reasons to make the containg structure also parametric, for example

``` julia
struct MyStuct{T1,T2}
  dt::DateTimeStandard{T1,T2}
end
```

Future version of CFTime might add other type parameters.
Internally, `T1` corresponds to a `CFTime.Period{T,Tfactor,Texponent}` structure  wrapping a number type T representing the duration expressed in seconds as:

```
duration * factor * 10^exponent
```

where `Tfactor` and `Texponent` are value types of `factor` and `exponent` respectively.
`T2` is a value type of the date origin tuple represented as `(year, month, day,...)`.
