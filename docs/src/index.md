# CFTime.jl

This package implements the calendar types from the [CF convention](http://cfconventions.org/Data/cf-conventions/cf-conventions-1.12/cf-conventions.html#calendar), namely:

* Mixed Gregorian/Julian calendar  (`DateTimeStandard`)
* Proleptic gregorian calendar (`DateTimeProlepticGregorian`)
* Gregorian calendar without leap years (all years are 365 days long) (`DateTimeNoLeap`)
* Gregorian calendar with only leap year (all years are 366 days long) (`DateTimeAllLeap`)
* A calendar with every year being 360 days long (divided into 30 day months) (`DateTime360Day`)
* Julian calendar (`DateTimeJulian`)

Note that time zones and leap seconds are not supported by `CFTime.jl`.


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

The `convert` function can be used to convert dates between the different calendars:

```julia
convert(DateTime,DateTimeJulian(2024,4,4))
# 2024-04-17T00:00:00

convert(DateTimeJulian,DateTime(2024,4,17))
# DateTimeJulian(2024-04-04T00:00:00)
```


```@docs
convert(::Type{DateTime}, dt::DateTimeStandard)
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

## Ranges


Time ranges can be constructed using a start date, end date and a time increment:

```julia
range = DateTimeStandard(2000,1,1):Dates.Day(1):DateTimeStandard(2000,12,31)
length(range)
# returns 366
step(range)
# returns 1 day
```

Note that there is no default increment for range.

## Rounding

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

The functions `floor` and `ceil` are also supported. They can be used to effectively reduce the time resolution, for example:

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



## Type-stable constructors

To create a type-stable date time structure, use the `DateTimeStandard` (and similar) either with the default `units` and time `origin`, a constant unit/origin or a value type of the unit and origin. For example:

```julia
using CFTime: DateTimeStandard

foo(year,month,day,hour,minute,second) = DateTimeStandard(year,month,day,hour,minute,second; units=:second, origin=(1970,1,1))

# Type-stable thanks to constant propagation
@code_warntype foo(2000,1,1,0,0,0)


foo2(year,month,day,hour,minute,second,units,origin) = DateTimeStandard(year,month,day,hour,minute,second; units, origin)

# This not type-stable as the type depends on the value of units and origin
units = :second
origin = (1970,1,1)
@code_warntype foo2(2000,1,1,0,0,0,units,origin)


# But this is again type-stable
units = Val(:second)
origin = Val((1970,1,1))
@code_warntype foo2(2000,1,1,0,0,0,units,origin)
```


## Internal API

For CFTime 0.1.4 and before all date-times are encoded using internally milliseconds since a fixed time origin and stored as an `Int64` similar to julia's `Dates.DateTime`.
However, this approach does not allow to encode time with a sub-millisecond precision allowed by the CF convention and supported by e.g. [numpy](https://numpy.org/doc/1.25/reference/arrays.datetime.html#datetime-units). While `numpy` allows attosecond precision, it can only encode a time span of ±9.2 around the date 00:00:00 UTC on 1 January 1970. In CFTime the time origin and the number containing the duration and the time precision are now encoded as two additional type parameters.

When wrapping a CFTime date-time type, it is recommended for performance reasons to make the containg structure also parametric, for example

``` julia
struct MyStuct{T1,T2}
  dt::DateTimeStandard{T1,T2}
end
```

Future version of CFTime might add other type parameters.
Internally, `T1` corresponds to a `CFTime.Period{T,Tfactor,Texponent}` structure  wrapping a number type `T` representing the duration expressed in seconds as:

```
duration * factor * 10^exponent
```

where `Tfactor` and `Texponent` are value types of `factor` and `exponent` respectively.

For example, duration 3600000 milliseconds is represented as `duration = 3600000`,
`Tfactor = Val(1)`, `Texponent = Val(-3)`, as

```
3600000 milliseconds = 3600000 * 1 * 10⁻³ seconds
```

or the durtion 1 hours is `duration = 1`,  `Tfactor = Val(3600)` and `Texponent = Val(0)` since:

```
1 hour = 3600 * 1 * 10⁰ seconds
```

There is no normalization of the time duration per default as it could lead to under-/overflow.

The type parameter `T2` of `DateTimeStandard` encodes the time origin as a tuple of integers starting with the year (year,month,day,hour,minute,seconds,milliseconds,microseconds,...).  Only the year, month and day need specified; all other default to zero.
For example `T2` would be `Val((1970,1,1))` if the time origin is the 1st January 1970).

By using value types as type parametes, the time origin, time resolution... are known to the compiler.
For example, computing the difference between between two date time expressed in as the same time origin and units as a single substraction:

```julia
using BenchmarkTools
using Dates
using CFTime: DateTimeStandard

dt0 = DateTimeStandard(1,"days since 2000-01-01")
dt1 = DateTimeStandard(1000,"days since 2000-01-01")

difference_datetime(dt0,dt1) = Dates.Millisecond(dt1 - dt0).value
@btime difference_datetime($dt0,$dt1)

# output (minimum of 5 @btime trails)
# 1.689 ns (0 allocations: 0 bytes)

v0 = 1
v1 = 1000

difference_numbers(v0,v1) = (v1-v0)*(86_400_000)
@btime difference_numbers($v0,$v1)

# output (minimum of 5 @btime trails)
# 1.683 ns (0 allocations: 0 bytes)
```

The information in this section and any other information marked as internal or experimental is not part of the public API and not covered by the semantic versioning.
Future version of CFTime might add or changing the meaning of type parameters as patch-level changes. However removing a type parameter would be considered as a breaking change.
