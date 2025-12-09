


| Module           |  median | minimum |    mean | std. dev. |
|:---------------- | -------:| -------:| -------:| ---------:|
| julia-CFTime-cpu | 0.03667 | 0.03066 | 0.04164 |   0.01604 |
| julia-CFTime-gpu | 0.00178 | 0.00177 | 0.00178 |   0.00002 |
| julia-Dates      | 0.02281 | 0.01710 | 0.02575 |   0.01260 |
| python-cftime    | 3.71141 | 3.68062 | 3.71466 |   0.01784 |
| python-numpy     | 0.02341 | 0.02330 | 0.02363 |   0.00077 |


julia 1.12.0, Dates 1.11.0, CFTime 0.2.5, python 3.12.4, python-cftime 1.6.5, numpy 2.3.5
Hardware: AMD EPYC 7A53 64-Core Processor, AMD Instinct MI250X (LUMI)


Note: GPU support is experimental. CUDA.jl in known not to work. This test uses AMDGPU.jl 1.3.6