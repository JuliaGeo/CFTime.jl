# CFTime.jl

This package implement the calendar types from the [CF convention](http://cfconventions.org/Data/cf-conventions/cf-conventions-1.7/cf-conventions.html#calendar), in namely:

* Mixed Gregorian/Julian calendar
* Proleptic gregorian calendar
* Gregorian calendar without leap years (all years are 365 days long)
* Gregorian calendar with only leap year (all years are 366 days long)
* A calendar with every year being 360 days long (divided into 30 day months)
* Julian calendar


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

