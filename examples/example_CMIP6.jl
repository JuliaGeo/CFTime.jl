
# # Example
#
# This example shows how to use the CFTime package with CMIP6 data
# in the NetCDF format following the CF Conventions.
#
# The CMIP6 example data is from NOAA-GFDL and included in the R package CFtime.

using NCDatasets, CFTime, Dates, Statistics
using Downloads: download


url = "https://github.com/R-CF/CFtime/raw/1509a2387a92bda8500d1d6ac472b36df3575b56/inst/extdata/pr_day_GFDL-ESM4_ssp245_r1i1p1f1_gr1_20150101-20991231_v20180701.nc"
fname = download(url)

# Open the NetCDF file
ds = NCDataset(fname);

# Get the global attriute Conventions
ds.attrib["Conventions"]

# Get the calendar and units attriute of the variable time
calendar = ds["time"].attrib["calendar"]
units = ds["time"].attrib["units"]

# Load the raw data representing the number of days since 1850-01-01 with the
# noleap calendar
data = ds["time"].var[:];

# Decode the data and return a vector of `DateTimeNoLeap`
time = CFTime.timedecode(data,units,calendar)
time[1:3]

# Since CFTime is integrated in NCDatasets, this transformation above
# is handeld autmatically by using:
time = ds["time"][:];

# Load the precitipation which is a variable of the size 1 x 1 x 31025
pr = ds["pr"][1,1,:];
close(ds)

# Verify that the time series cover a complete years
(time[1],time[end])

# Get all unique years
years = unique(Dates.year.(time));

# Compute mean and standard deviation per year
pr_yearly_mean = [mean(pr[Dates.year.(time) .== y]) for y in years];
pr_yearly_std = [std(pr[Dates.year.(time) .== y]) for y in years];

using CairoMakie
