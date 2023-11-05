using CFTime
import CFTime: timetuplefrac, datetuple_ymd

struct DateTime2{T,base,origintupe}
    instant::T
end


Val(1000)

origintuple = (2000,1,1,0,0,0.0)

Val(origintuple)

Val((1000,20))


# if base is 1 then the units of instant is seconds
instant = 1
T = typeof(instant)
base = 24*60*60


dt = DateTime2{T,Val(base),Val(origintuple)}(instant)


y,m,d,H,M,S = origintuple

# in seconds
time = 24*60*60 * (
    dt.instant + (CFTime.datenum_gregjulian(y,m,d,true,false) * 24*60*60) / base)

days,h,mi,s,ms = timetuplefrac(time*1000)
y, m, d = datetuple_ymd(DateTimeStandard,days)

@show y, m, d, h,mi,s,ms

unwrap(::Val{x}) where x = x

# function datetuple_ymd(dt::DateTime2{T,Tbase,origintuple}) where {T,Tbase,origintuple}
#     base = unwrap(Tbase)
#     y,m,d,H,M,S = unwrap(origintuple)

#     #time = dt.instant + (CFTime.datenum_gregjulian(y,m,d,true,false) * 24*60*60) / base
#     time = dt.instant

#     days,h,mi,s,ms = timetuplefrac(time)
#     y, m, d = datetuple_ymd(T,days)
#     return y, m, d, h, mi, s, ms


#     CFTime.datetuple(2)
# end

# @show datetuple_ymd(dt)

#@code_native datetuple_ymd(dt)

#datetuple_gregjulian(Z,false,_hasyear0(DateTimeJulian))
#CFTime
