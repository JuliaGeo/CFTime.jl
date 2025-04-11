---
title: 'CFTime.jl: a Julia package for time types conforming to the Climate and Forecasting (CF) conventions'
tags:
  - julia
  - climate-and-forecast-conventions
  - oceanography
  - meteorology
  - earth-observation
  - climatology
  - netcdf
authors:
  - name: Alexander Barth
    orcid: 0000-0003-2952-5997
    affiliation: 1
affiliations:
 - name: GHER, University of Liège, Liège, Belgium
   index: 1
date: 13 January 2024
bibliography: paper.bib
---

# Summary


Climate and Forecasting (CF) conventions are a metadata standard for Earth data [@Eaton2024] and are mainly used in oceanography and meteorology.
They aim to be equally applicable to model data, remote-sensing data and in-situ data, despite the high heterogeneity among data types.
The CF conventions were originally proposed for the NetCDF storage format, but they are also increasingly used with other formats like Zarr [@OGC_Zarr] and GRIB ([GRIBDatasets](https://github.com/JuliaGeo/GRIBDatasets.jl)).

Since the initial release of the Climate and Forecasting (CF) conventions [@Eaton2003], the encoding of time instances has been standardized. This part of the standard is based on the earlier COARDS (Cooperative Ocean Atmosphere Research Data Service) standard from 1995 [@COARDS]. The Julia package CFTime implements various standardized calendars that have been standardized in the frame of these conventions. It also supports some arithmetic operations for example, computing the duration between two time instances, ordering time instances and creating time ranges. The time origin and resolution are flexible ranging from days to attoseconds.


# Statement of need

In many Earth science disciplines and beyond, expressing a time instance and a duration is essential. The CF conventions provide a rich and flexible
framework for handling time, equally applicable to observations and model data. To our knowledge, CFTime.jl is the only package in the Julia ecosystem that implements the time structures standardized by the CF conventions. While almost all datasets used in Earth Science use dates after the year 1582, some datasets or software systems use a time origin before this date, which makes it necessary to handle the transition from Julian to Gregorian calendar [@Octave; @SeaDataNet_format].
Some users also expressed the need for microseconds and nanoseconds as time resolution. In particular, the popular Python package Pandas [@mckinney-proc-scipy-2010] defaults to nanoseconds as the time resolution. It was therefore necessary to also support sub-second time resolutions, even if they are rarely used in typical Earth science applications.

As of 31 March 2025, 119 Julia packages depend directly or indirectly on CFTime (excluding optional dependencies). CFTime is for example used by numerical models, such as ClimaOcean.jl, a framework for realistic ocean and coupled sea-ice simulations based on Oceananigans.jl [@OceananigansJOSS], the hydrological modeling package Wflow.jl [@vanVerseveld2024] and AIBECS.jl, a modeling framework for global marine biogeochemical cycles [@Pasquier2022].

Several data-related packages also make direct or indirect use of CFTime, such as the NetCDF manipulation package NCDatasets.jl [@Barth2024], the gridded data processing package YAXArrays.jl [@Gans2023] and packages for handling in-situ data from various observing platforms (OceanRobots.jl [@Forget2024] and ArgoData.jl [@Forget2025]).

# Installation

CFTime supports Julia 1.6, and later and can be installed with the Julia package manager using the following command:

```julia
using Pkg
Pkg.add("CFTime")
```
CFTime is a pure Julia package and currently depends only on the modules `Dates` and `Printf`, which are part of Julia’s standard library.

# Features

In the context of the CF conventions, a time instance is represented as a time offset measured from a time origin (in UTC): for example, the value 86400 with units "seconds since 1970-01-01 00:00:00" is 2 January 1970, 00:00:00 UTC. The units of the time offset and the time origin are stored in the `units` attribute of the time variable.

The `calendar` attribute of a NetCDF or Zarr time variable defines how the time offset and units are interpreted to derive the calendar year, month, day, hour, and so on.
The CF conventions define several calendar types, including:

| Calendar                | Type                         | Explanation |
| ----------------------- | ---------------------------- | ---------------------------- |
| `standard`, `gregorian` | `DateTimeStandard`           | the Gregorian calendar after 15 October 1582 and the Julian calendar before  |
| `proleptic_gregorian`   | `DateTimeProlepticGregorian` | the Gregorian calendar applied to all dates (including before 15 October 1582) |
| `julian`                | `DateTimeJulian`             | the Julian calendar applied to all dates (including after 15 October 1582) |
| `noleap`, `365_day`     | `DateTimeNoLeap`             | calendar without leap years |
| `all_leap`, `366_day`   | `DateTimeAllLeap`            | calendar with only leap years |
| `360_day`               | `DateTime360Day`             | calendar assuming that all months have 30 days |


The Gregorian calendar was introduced to account for the fact that a solar year is not exactly 365.25 days, but is more closely approximated by 365.2422 days. In the standard calendar, the day Thursday, 4 October 1582 (the last day of the Julian calendar) is followed by the first day of the Gregorian calendar, Friday, 15 October 1582 (the date of introduction of the Gregorian calendar).

CFTime is based on the Meeus' algorithm [@Meeus98] for the Gregorian and Julian calendars, with two adaptations:

* The original algorithm is based on floating-point arithmetic. The algorithm in CFTime is implemented using integer arithmetic, which is more efficient.
Additionally, underflows and overflows are easier to predict and handle with integer arithmetic.
* The Meeus' algorithm has been extended to dates prior to 100 BC.

The Meeus' algorithm is very compact, efficient, requires very few branches, and does not need large tables of constants. For verification purposes, the
algorithm used in the cftime python package [@Whitaker2024] was ported to Julia, which is less efficient but significantly easier to audit for correctness.

The following is a list of the main features of CFTime:

* Basic arithmetic, such as subtracting two time instances to compute their duration, or adding a duration to a time instance.
* Supporting a wide range of the time resolutions, from days down to attoseconds. Even if the use of attoseconds is quite unlikely in the context of earth science data, it has been added for feature parity with NumPy's date time type [@harris2020array; @numpy].
* Supporting arbitrary time origins. Since the time origin for NumPy's date time type is fixed to be 1 January 1970 at 00:00, the usefulness of some time units is limited. As an extreme example, with attoseconds, all NumPy's date times can only express a time span of +/- 9.2 s around the time origin since a 64-bit integer is used internally. For CFTime.jl the time origin is arbitrary and part of the parametric type definition and not an additional field of the time data structure. As a consequence, a large array of date times with common time origin only need to store the time counter (also a 64-bit integer by default) for every element, which makes this case as memory efficient as NumPy's or Julia's default date time for this common use case.

* By default, the time counter is a 64-bit integer, but other integer types (such as 32-bit, 128-bit, or Julia's arbitrary-sized integer `BigInt`) or floating-point types can be used. Using an integer to encode a time instance is recommended for most applications, as it makes reasoning about the time resolution easier. Julia's compiler optimizes all functions and methods for the chosen types, ensuring optimal run-time performance.
* Conversion function between CFTime types and Julia's `DateTime`.
* Regular time range based on Julia's range type. A time range is a vector of date time elements, but only the start time, the end time and the steps need to be stored in memory.


The flexibility of CFTime's datetime comes with some cost. When merging data from different sources with different time origins and units, the resulting merged time vector may not have a concrete type, as there is no implicit conversion to a common time origin or internal unit, unlike Julia's `DateTime`. In some cases, the user might decide to explicitly convert all times to a common time origin and internal unit for optimal performance. Another limitation is that CFTime currently does not support leap seconds, which were standardized as part of CF conventions version 1.12, released in December 2024.

# Similar software

This julia package, CFTime, has been highly influenced by Python's cftime [@Whitaker2024], which is also used in libraries such as xarray [@hoyer2017xarray].
In the R ecosystem, the CFtime package serves a similar purpose and scope [@vanLaake2025] to this package.
Among Julia packages, [NanoDates.jl](https://github.com/JuliaTime/NanoDates.jl) and [TimesDates.jl](https://github.com/JeffreySarnoff/TimesDates.jl) for representing time with a nanosecond precision and [AstroTime.jl](https://github.com/JuliaAstro/AstroTime.jl) for astronomical time scales should also be mentioned.


# Acknowledgements

I thank [all contributors](https://github.com/JuliaGeo/CFTime.jl/graphs/contributors) to this package, in particular Martijn Visser, Fabian Gans, Rafael Schouten and Yeesian Ng. I also acknowledge Jeff Whitaker and [contributors](https://github.com/Unidata/cftime/graphs/contributors) for Python's [cftime](https://github.com/Unidata/cftime) which has helped the development of this package by providing reference values and a reference implementation for tests.

# Funding

Acknowledgement is given to the F.R.S.-FNRS (Fonds de la Recherche Scientifique de Belgique) for funding the position of Alexander Barth. This work was partly performed with funding from the Blue-Cloud 2026 project under the Horizon Europe programme, Grant Agreement No. 101094227.

# References

<!--  LocalWords:  CFTime jl julia netcdf orcid GHER Liège situ Zarr
 -->
<!--  LocalWords:  NetCDF grib GRIBDatasets COARDS nd gregorian Meeus
 -->
<!--  LocalWords:  DateTimeStandard proleptic julian DateTimeJulian
 -->
<!--  LocalWords:  DateTimeProlepticGregorian noleap DateTimeNoLeap
 -->
<!--  LocalWords:  DateTimeAllLeap DateTime cftime dataset SeaDataNet
 -->
<!--  LocalWords:  ClimaOcean Oceananigans hydrological Wflow AIBECS
 -->
<!--  LocalWords:  modelling biogeochemical NCDatasets gridded Printf
 -->
<!--  LocalWords:  YAXArrays OceanRobots ArgoData attoseconds numpy's
 -->
<!--  LocalWords:  datetime datetimes julia's BigInt timerange xarray
 -->
<!--  LocalWords:  CFTimes CFtime NanoDates TimesDates AstroTime de
 -->
<!--  LocalWords:  Acknowledgements Fonds Scientifique Belgique Gans
 -->
<!--  LocalWords:  Martijn Visser Schouten Yeesian Ng programme
 -->
