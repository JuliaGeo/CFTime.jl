using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple
using Dates
using Test
using BenchmarkTools

const DIVI = (
    (:day, 1, 24*60*60*1000),
    (:hour, 1, 60*60*1000),
    (:minute, 1, 60*1000),
    (:second, 1, 1000),
    (:millisecond,    1, 1),
    (:microsecond, 10^3, 1),
    (:nanosecond,  10^6, 1),
)

unwrap(::Val{x}) where x = x

"""

base is the ratio of units of duration and milliseconds.
It is a value type.

| base | duration units |
|------|----------------|
|    1 | milliseconds |
|    1/1000 | microseconds |
"""
struct Period{T,base}
    duration::T
end

Period(duration,base) = Period{typeof(duration),Val(base)}(duration)

_base(p::Period{T,base}) where {T,base} = unwrap(base)


@inline __tf(result,time) = result
@inline function __tf(result,time,d1,dn...)
   if d1 == 0
       __tf((result...,0),0,dn...)
   else
       p = fld(time, d1)
       time2 = time - p*d1
       __tf((result...,p),time2,dn...)
    end
end
@inline tf(time,divi) = __tf((),time,divi...)


function timetuplefrac(t::Period{T,Tbase}) where {T,Tbase}
    # for integers
    divi = getindex.(DIVI,3) .÷ (getindex.(DIVI,2) .* _base(t))
    time = t.duration

    tf(time,divi)
end

#@code_warntype tf(time,divi)



@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5)*1000,1))[1:4] == (2,3,4,5)


@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5),1000))[1:4] == (2,3,4,5)



#@btime tf($time,$divi)


#@code_warntype tf(time,divi)

#@test tf(time,divi)[1:4] == (2,3,4,5)


struct DateTime2{T,origintupe}
    instant::T
end

function DateTime2(t,units::AbstractString)
    origintuple, base = timeunits(Tuple,units)

    instant = Period(t,base)
    dt = DateTime2{typeof(instant),Val(origintuple)}(instant)
end

function datetuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple}
    base = _base(dt.instant)
    origintuple = unwrap(Torigintuple)
    y,m,d,H,M,S = origintuple
    time = (dt.instant.duration*base +
        (((CFTime.datenum_gregjulian(y,m,d,true,false) * 24 + H)*60 + M)*60 + S)*1000)

    days,h,mi,s,ms = timetuplefrac(time)
    y, m, d = datetuple_ymd(DateTimeStandard,days)

    return y, m, d, h, mi, s, ms
end


dt = DateTime2(1,"milliseconds since 2000-01-01")
@test (2000, 1, 1, 0, 0, 0, 1) == datetuple(dt)


dt = DateTime2(10^9,"nanoseconds since 2000-01-01")
@test (2000, 1, 1, 0, 0, 1, 0) == datetuple(dt)

dt = DateTime2(10^9,"nanoseconds since 2000-01-01T23:59:59")
@test (2000, 1, 2, 0, 0, 0, 0) == datetuple(dt)


#broken
#dt = DateTime2(1,"microseconds since 2000-01-01")
#@test (2000, 1, 1, 0, 0, 1, 0) == datetuple(dt)
