using NCDatasets, CFTime, Dates, Statistics
using Downloads: download

# CMIP6 example data from NOAA-GFDL included in the R package CFtime

fname = download("https://github.com/R-CF/CFtime/raw/1509a2387a92bda8500d1d6ac472b36df3575b56/inst/extdata/pr_day_GFDL-ESM4_ssp245_r1i1p1f1_gr1_20150101-20991231_v20180701.nc")

# open the NetCDF file
ds = NCDataset(fname)

# get the global attriute Conventions
ds.attrib["Conventions"]
# output: CF-1.7 CMIP-6.0 UGRID-1.0

# get the calendar and units attriute of the variable time
calendar = ds["time"].attrib["calendar"]
# output: noleap

units = ds["time"].attrib["units"]
# "days since 1850-01-01"

# load the raw data representing the number of days since 1850-01-01 with the
# noleap calendar
data = ds["time"].var[:];

# decode the data and return a vector of DateTimeNoLeap
time = CFTime.timedecode(data,units,calendar)
eltype(time) <: DateTimeNoLeap
# output: true

# since CFTime is integrated in NCDatasets, this transformation above
# is handeld autmatically by using:
time = ds["time"][:];

# load the precitipation which is a variable of the size 1 x 1 x 31025
pr = ds["pr"][1,1,:];

# verify that the time series cover a complete years
@show time[1]
@show time[end]

# all unique years
years = unique(Dates.year.(time))

# compute mean and standard deviation per year
pr_yearly_mean = [mean(pr[Dates.year.(time) .== y]) for y in years]
pr_yearly_std = [std(pr[Dates.year.(time) .== y]) for y in years]

