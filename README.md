# CFTime

[![Build Status Linux and macOS](https://travis-ci.org/Alexander-Barth/CFTime.jl.svg?branch=master)](https://travis-ci.org/Alexander-Barth/CFTime.jl)
[![Build Status Windows](https://ci.appveyor.com/api/projects/status/github/Alexander-Barth/CFTime.jl?branch=master&svg=true)](https://ci.appveyor.com/project/Alexander-Barth/ncdatasets-jl)

[![Coverage Status](https://coveralls.io/repos/Alexander-Barth/CFTime.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/Alexander-Barth/CFTime.jl?branch=master)
[![codecov.io](http://codecov.io/github/Alexander-Barth/CFTime.jl/coverage.svg?branch=master)](http://codecov.io/github/Alexander-Barth/CFTime.jl?branch=master)

[![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://alexander-barth.github.io/CFTime.jl/stable/)
[![documentation latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://alexander-barth.github.io/CFTime.jl/latest/)


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

# "360 day" calendar

CFTime.timeencode(dt,"days since 2000-01-01 00:00:00")
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0

dt = CFTime.timedecode([0,1,2,3],"days since 2000-01-01 00:00:00","360_day")
# 4-element Array{DateTime360Day,1}:
#  DateTime360Day(2000-01-01T00:00:00)
#  DateTime360Day(2000-01-02T00:00:00)
#  DateTime360Day(2000-01-03T00:00:00)
#  DateTime360Day(2000-01-04T00:00:00)

dt[2]-dt[1]
# 86400000 milliseconds

Dates.Day(dt[2]-dt[1])
# 1 day

CFTime.timeencode(dt,"days since 2000-01-01 00:00:00","360_day")
# 4-element Array{Float64,1}:
#  0.0
#  1.0
#  2.0
#  3.0

DateTime360Day(2000,1,1) + Dates.Day(360)
# DateTime360Day(2001-01-01T00:00:00)
```
