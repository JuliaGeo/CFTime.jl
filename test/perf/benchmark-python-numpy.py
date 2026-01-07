# Install dependencies via the shell command:
#
# pip install numpy

import numpy as np
import timeit
import sys


def compute(offset):
    t0 = np.datetime64("1900-01-01") + offset.astype("timedelta64[s]")
    t1 = np.datetime64("2000-01-01") + offset.astype("timedelta64[s]")
    diff = t1 - np.flip(t0)
    month = t0.astype('datetime64[M]').astype("int64") % 12 + 1
    return diff.astype("int64").mean(), month.mean()

if __name__ == "__main__":
    print("python: ",sys.version)
    print("numpy: ",np.__version__)

    n = 1_000_000
#    n = 100_000
    offset = np.arange(0,n)

    mean_total_seconds = compute(offset)
    print("mean_total_seconds: ", mean_total_seconds)


    setup = "from __main__ import compute"
    benchtime = timeit.repeat(lambda: compute(offset), setup=setup,number = 1, repeat = 100)

    print("min time: ",min(benchtime))

    with open("python-numpy.txt","w") as f:
        for bt in benchtime:
            print(bt,file=f)
