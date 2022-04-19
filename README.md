# CFTime

[![Build Status](https://github.com/JuliaGeo/CFTime.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/CFTime.jl/actions)
[![Coverage Status](https://coveralls.io/repos/JuliaGeo/CFTime.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaGeo/CFTime.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaGeo/CFTime.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGeo/CFTime.jl?branch=master)
[![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliageo.github.io/CFTime.jl/stable/)
[![documentation latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliageo.github.io/CFTime.jl/latest/)


`CFTime` encodes and decodes time units conforming to the Climate and Forecasting (CF) netCDF conventions.
`CFTime` was split out of the [NCDatasets](https://github.com/Alexander-Barth/NCDatasets.jl) julia package.


## Installation

Inside the [Julia](https://julialang.org/) shell, you can download and install the package by issuing:

```julia
using Pkg
Pkg.add("CFTime")
```

## Example

```julia
using CFTime, Dates

# standard calendar

dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00")
# 4-element Array{Dates.DateTime,1}:
#  2000-01-01T00:00:00
#  2000-01-02T00:00:00
#  2000-01-03T00:00:00
#  2000-01-04T00:00:00


CFTime.timeencode(dt,"days since 2000-01-01 00:00:00")
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0

# "360 day" calendar

dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00",DateTime360Day)
# 4-element Array{DateTime360Day,1}:
#  DateTime360Day(2000-01-01T00:00:00)
#  DateTime360Day(2000-01-02T00:00:00)
#  DateTime360Day(2000-01-03T00:00:00)
#  DateTime360Day(2000-01-04T00:00:00)

dt[2]-dt[1]
# 86400000 milliseconds

Dates.Day(dt[2]-dt[1])
# 1 day

CFTime.timeencode(dt,"days since 2000-01-01 00:00:00",DateTime360Day)
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0

DateTime360Day(2000,1,1) + Dates.Day(360)
# DateTime360Day(2001-01-01T00:00:00)
```


You can replace in the example above the type `DateTime360Day` by the string `"360_day"` (the name according to the CF conversion).

## Parsing dates

Dates can be parsed by using `dateformat` from julia's `Dates` module, for example:

```julia
dt = DateTimeNoLeap("21001231",dateformat"yyyymmdd");
# or
# dt = parse(DateTimeNoLeap,"21001231",dateformat"yyyymmdd")
Dates.year(dt),Dates.month(dt),Dates.day(dt)
# output (2100, 12, 31)
```

## Acknowledgments

Thanks to Jeff Whitaker and [contributors](https://github.com/Unidata/cftime/graphs/contributors) for python's [cftime](https://github.com/Unidata/cftime) released under the MIT license which has helped the developpement of this package.
