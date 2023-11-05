using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits
using Dates

# if base is 1 then the units of instant is seconds
# if base is 60 then the units of instant is minutes
# if base is 1//1000 then the units of instant is milliseconds


struct Period{T,base}
    duration::T
end


struct DateTime2{T,base,origintupe}
    instant::T
end



t0, plength = timeunits(Tuple,"days since 2000-01-01")

origintuple = (2000,1,1,0,0,0.0)


base = 1//1000
instant = 1
T = typeof(instant)


dt = DateTime2{T,Val(base),Val(origintuple)}(instant)


y,m,d,H,M,S = origintuple

# in seconds
time =  (dt.instant*base + (CFTime.datenum_gregjulian(y,m,d,true,false) * 24*60*60))
days,h,mi,s,ms = timetuplefrac(time*1000)
y, m, d = datetuple_ymd(DateTimeStandard,days)


@test (2000, 1, 1, 0, 0, 0, 1) == (y, m, d, h,mi,s,ms)

#@show y, m, d, h,mi,s,ms

unwrap(::Val{x}) where x = x

function datetuple_ymd(dt::DateTime2{T,Tbase,Torigintuple}) where {T,Tbase,Torigintuple}
     base = unwrap(Tbase)
     origintuple = unwrap(Torigintuple)
     y,m,d,H,M,S = origintuple
    time =  (dt.instant*base + (CFTime.datenum_gregjulian(y,m,d,true,false) * 24*60*60))
    days,h,mi,s,ms = timetuplefrac(time*1000)
    y, m, d = datetuple_ymd(DateTimeStandard,days)

    return y, m, d, h, mi, s, ms
end


@test (2000, 1, 1, 0, 0, 0, 1) == datetuple_ymd(dt)
