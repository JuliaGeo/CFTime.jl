# Install dependencies via the shell commands:
#
# pip install cftime numpy

import numpy as np
import cftime
import timeit
import sys
import cftime
import datetime

def compute(n):
    t0 = cftime.num2date(np.arange(n),"milliseconds since 1000-01-1")
    t1 = cftime.num2date(np.arange(n),"milliseconds since 2000-01-1")

    diff = t1 - np.flip(t0)

    mean_total_seconds = np.vectorize(lambda d: d.total_seconds(),otypes = [int])(diff).mean()
    return mean_total_seconds


if __name__ == "__main__":
    n = 100_000
#    n = 100_000
    mean_total_seconds = compute(n)
    print("mean_total_seconds: ", mean_total_seconds)

    setup = "from __main__ import compute"
    benchtime = timeit.repeat(lambda: compute(n), setup=setup,number = 1, repeat = 100)

    print("min time: ",min(benchtime))

    with open("python-cftime.txt","w") as f:
        for bt in benchtime:
            print(bt,file=f)


# timedelta = np.arange(100000,dtype = np.dtype('timedelta64[ms]'))
#
# ufunc 'add' cannot use operands with types dtype('O') and dtype('<m8[ms]')
# t0 = cftime.DatetimeGregorian(2000,1,1) + timedelta

# print(type(timedelta),timedelta.dtype)

# dt_25s = np.dtype('timedelta64[ms]')
# np.datetime_data(dt_25s)
# np.array(10, dt_25s).astype('timedelta64[s]')
# xx = np.array([10,2], dtype = np.dtype('timedelta64[ms]'))
# print(xx,type(xx))

#y = cftime.DatetimeGregorian(2000,1,1) + xx

# cftime.num2date
# ?cftime.num2date
# cftime.num2date([1,2,3])
# cftime.num2date([1,2,3],"milliseconds since 1000-01-10")
# cftime.num2date([1,2,3],"milliseconds since 1000-01-10")
# np.arange(0,100)
# x = np.arange(0,100)
# t0 = cftime.num2date(x,"milliseconds since 1000-01-10")
# t1 = cftime.num2date(x,"milliseconds since 1000-01-10")
# t1 - t0
# t1 = cftime.num2date(x,"milliseconds since 1000-01-10")
# t1 = cftime.num2date(x,"milliseconds since 2000-01-10")
# t1 - t0
# (t1 - t0)
# aa = (t1 - t0)[0]
# aa
# typeof(aa)
# type(aa)
# import datetime
# datetime.timedelta
# ?datetime.timedelta
# datetime.timedelta.seconds
# datetime.timedelta.seconds(aa)
# datetime.timedelta.seconds
# aa.seconds()
# aa.seconds()
# a
# a
# aa
# aa.seconds
# t1 - t0
# %history
