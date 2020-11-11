# CFTime

[![Build Status Linux and macOS](https://travis-ci.com/JuliaGeo/CFTime.jl.svg?branch=master)](https://travis-ci.com/JuliaGeo/CFTime.jl)
[![Build Status Windows](https://ci.appveyor.com/api/projects/status/dhk8nfaty2c2ko67?svg=true)](https://ci.appveyor.com/project/Alexander-Barth/cftime-jl-vwcs5)

[![Coverage Status](https://coveralls.io/repos/JuliaGeo/CFTime.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaGeo/CFTime.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaGeo/CFTime.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGeo/CFTime.jl?branch=master)

[![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliageo.github.io/CFTime.jl/stable/)
[![documentation latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliageo.github.io/CFTime.jl/latest/)


`CFTime` encodes and decodes time units conforming to the Climate and Forecasting (CF) netCDF conventions.
`CFTime` was split out of the [NCDatasets](https://github.com/Alexander-Barth/NCDatasets.jl) julia package.


## Installation

Inside the Julia shell, you can download and install the package by issuing:

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
