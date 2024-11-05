
uname -a
cat /etc/issue
cat /proc/cpuinfo | grep 'model name' | head -n 1

echo "---------------------------"

julia benchmark-julia.jl

echo "---------------------------"

python3 benchmark-python-cftime.py

echo "---------------------------"

python3 benchmark-python-numpy.py

echo "---------------------------"


julia summary.jl
