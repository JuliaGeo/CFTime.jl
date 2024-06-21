using CFTime
using Test

include("reference_algorithm.jl")


test_years(T,max_year::Integer) = test_years(T,-max_year:max_year)

function test_years(T,yearrange::AbstractRange)
    nsuccess = Int128(0)
    fails = Int64[]

    for year = yearrange
        if (year != 0) || ((year == 0) && CFTime._hasyear0(T))
            for Z in (CFTime.datenum(T,year,1,1):1:CFTime.datenum(T,year+1,1,1))[1:end-1]
                MYMD = CFTime.datetuple_ymd(T,Z);
                RYMD = Reference.datetuple_ymd(T,Z);

                if MYMD == RYMD
                    nsuccess += 1
                else
                    push!(fails,Z)
                end

                Z2 = CFTime.datenum(T,MYMD...)

                if Z == Z2
                    nsuccess += 1
                else
                    push!(fails,Z)
                end
            end
        end
    end
    return (nsuccess,fails)
end


yearrange = 1000:3000
yearrange = 1900:2000

if length(ARGS) > 0
    param = parse.(Int64,split(ARGS[1],','))
    yearrange = param[1]:param[2]
end

@show yearrange

for T in [DateTimeStandard, DateTimeJulian, DateTimeProlepticGregorian,
          DateTimeAllLeap, DateTimeNoLeap, DateTime360Day]

    nsuccess,fails = @time test_years(T,yearrange)

    println(T," success: ",nsuccess)
    println(T," fails: ",length(fails))

    if length(fails) > 0
        println.(fails);
    end
end
