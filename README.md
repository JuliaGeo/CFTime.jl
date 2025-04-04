# CFTime

[![Build Status](https://github.com/JuliaGeo/CFTime.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaGeo/CFTime.jl/actions)
[![codecov](https://codecov.io/gh/JuliaGeo/CFTime.jl/graph/badge.svg?token=A6XMcOvIFr)](https://codecov.io/gh/JuliaGeo/CFTime.jl)
[![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliageo.github.io/CFTime.jl/stable/)
[![documentation latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliageo.github.io/CFTime.jl/latest/)


`CFTime` encodes and decodes time units conforming to the [Climate and Forecasting (CF) conventions](https://cfconventions.org/).
`CFTime` was split out of the [NCDatasets](https://github.com/JuliaGeo/NCDatasets.jl) julia package.

Feature of CFTime include:

* Supporting a wide range of the time resolutions, from days down to attoseconds (for feature parity with NumPy's date time type)
* Supporting arbitrary time origins
* Per default, the time counter is a 64-bit integer, but other integers types (such as `Int32`, `Int128` or `BigInt`) or floating-point types can be used (not recommended)
* Basic arithmetic such as computing the duration between two time instances
* Conversion function between types and Julia's `DateTime`.
* Time range


## Installation

Inside the [Julia](https://julialang.org/) shell, you can download and install the package by issuing:

```julia
using Pkg
Pkg.add("CFTime")
```

## Example

For the Climate and Forecasting (CF) conventions, time is expressed as duration since starting time. The function `CFTime.timedecode` allows to convert these
time instances as a Julia `DateTime` structure:

```julia
using CFTime, Dates

# standard calendar

dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00")
# 4-element Array{Dates.DateTime,1}:
#  2000-01-01T00:00:00
#  2000-01-02T00:00:00
#  2000-01-03T00:00:00
#  2000-01-04T00:00:00
```


The function `CFTime.timeencode` does the inverse operation: converting a Julia `DateTime` structure to a duration since a start time:

```julia
CFTime.timeencode(dt,"days since 2000-01-01 00:00:00")
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0
```

The CF conventions also allow for calendars where every months has a duration of 30 days:

```julia
dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00",DateTime360Day)
# 4-element Array of DateTime360Day
#  DateTime360Day(2000-01-01T00:00:00)
#  DateTime360Day(2000-01-02T00:00:00)
#  DateTime360Day(2000-01-03T00:00:00)
#  DateTime360Day(2000-01-04T00:00:00)


CFTime.timeencode(dt,"days since 2000-01-01 00:00:00",DateTime360Day)
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0
```
You can replace in the example above the type `DateTime360Day` by the string `"360_day"` (the name for the calendar according to the CF conventions).

Single time instances can also be created by calling the corresponding constructor function, e.g. `DateTimeStandard` for the standard calendar (mixed Gregorian/Julian calendar)
in a similar way than Julias `DateTime` type.
The `units` argument specifies the time resolutions (either `day`, `hour`, ... `attosecond`) for the common case where the duration is specified as an integer.
For example, the 1 January 2000 + 1 ns would be:

```julia
y,m,d = (2000,1,1)
H,M,S = (0,0,0)
µS,mS,nS = (0,0,1)
DateTimeStandard(y,m,d,H,M,S,µS,mS,nS; units=:nanosecond)
# DateTimeStandard(2000-01-01T00:00:00.000000001)
```

As in Julia's `DateTime`, the default time resolution is milliseconds.
The duration are encoded internally as a 64-bit signed integer. High precision integer (or floating point numbers) can also be used, for example a 128-bit signed integer:


```julia
DateTimeStandard(Int128,y,m,d,H,M,S,µS,mS,nS; units=:nanosecond)
```

The default time origin is currently 1 January 1900 00:00:00. A different time origin can be used by setting the origin parameter:

```julia
DateTimeStandard(Int128,y,m,d,H,M,S,µS,mS,nS; units=:nanosecond, origin=(1970,1,1))
```

The units and origin argument can be wrapped as a `Val` to ensure that these values are known at compile-time:

```julia
DateTimeStandard(Int128,y,m,d,H,M,S,µS,mS,nS; units=Val(:nanosecond), origin=Val((1970,1,1)))
```

Several compile-time optimization have been implemented for the particular but common case where date have the same time origin and/or the same time resolution.

Arithmetic operations (`+`,`-`) and comparision operators on these types are supported, for example:


```julia
DateTimeStandard(2000,1,2) - DateTimeStandard(2000,1,1)
# 86400000 milliseconds

Dates.Day(DateTimeStandard(2000,1,2) - DateTimeStandard(2000,1,1))
# 1 day

DateTime360Day(2000,1,1) + Dates.Day(360)
# DateTime360Day(2001-01-01T00:00:00)

DateTimeStandard(2000,1,2) > DateTimeStandard(2000,1,1)
# true
```


## Parsing dates

Dates can be parsed by using `dateformat` from julia's `Dates` module, for example:

```julia
dt = DateTimeNoLeap("21001231",dateformat"yyyymmdd");
# or
# dt = parse(DateTimeNoLeap,"21001231",dateformat"yyyymmdd")
Dates.year(dt),Dates.month(dt),Dates.day(dt)
# output (2100, 12, 31)
```

## Alternatives

 * [NanoDates.jl](https://github.com/JuliaTime/NanoDates.jl): Dates with nanosecond resolved days
 * [TimesDates.jl](https://github.com/JeffreySarnoff/TimesDates.jl): Nanosecond resolution for Time and Date, TimeZones
 * [AstroTime.jl](https://github.com/JuliaAstro/AstroTime.jl): Astronomical time keeping in Julia

## Acknowledgments

Thanks to Jeff Whitaker and [contributors](https://github.com/Unidata/cftime/graphs/contributors) for python's [cftime](https://github.com/Unidata/cftime) released under the MIT license which has helped the developpement of this package by providing reference values and a reference implementation for tests. The algorithm is based on Jean Meeus' algorithm published in Astronomical Algorithms (2nd Edition, Willmann-Bell, p. 63, 1998) adapted to years prior to 300 AC.
