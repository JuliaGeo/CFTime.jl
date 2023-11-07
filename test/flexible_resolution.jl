using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple
using Dates
using Test
using BenchmarkTools

const DIVI = (
    (:day,            1, 24*60*60*1000),
    (:hour,           1,    60*60*1000),
    (:minute,         1,       60*1000),
    (:second,         1,          1000),
    (:millisecond,    1,             1),
    (:microsecond, 10^3,             1),
    (:nanosecond,  10^6,             1),
)

unwrap(::Val{x}) where x = x


"""
if T is a integer
duration * base / denom represents the time in milliseconds
"""
struct Period{T,base,denom}
    duration::T
end

Period(duration::Number,base,denom=1) = Period{typeof(duration),Val(base),Val(denom)}(duration)

_base(p::Period{T,base,denom}) where {T,base,denom} = unwrap(base)
_denom(p::Period{T,base,denom}) where {T,base,denom} = unwrap(denom)


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


function datenum_(tuf::Tuple,base,denom)
    divi = (denom .* getindex.(DIVI,3)) .÷ (getindex.(DIVI,2) .* base)
    return sum(divi[1:length(tuf)] .* tuf)
end

function timetuplefrac(t::Period{T,Tbase}) where {T,Tbase}
    # for integers
    base = _base(t)
    denom = _denom(t)
    divi = (denom .* getindex.(DIVI,3)) .÷ (getindex.(DIVI,2) .* base)
    time = t.duration

    tf(time,divi)
end


function Period(tuf::Tuple,base,denom=1)
    duration = datenum_(tuf,base,denom)
    Period{typeof(duration),Val(base),Val(denom)}(duration)
end

#@code_warntype tf(time,divi)



@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5)*1000,1))[1:4] == (2,3,4,5)


@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5),1000))[1:4] == (2,3,4,5)

base = 1000

#for tuf in (
#    (2,3,4,5),
tuf=    (2,3,4,5,6,7,8)
#    )
base = 1e-6
denom = 1

    p = Period(tuf,base)
    @test timetuplefrac(p)[1:length(tuf)] == tuf


base = 1
denom = 10^6

    p = Period(tuf,base,denom)
    @test timetuplefrac(p)[1:length(tuf)] == tuf


#end


@btime datenum_($tuf,$base,1)

#@btime tf($time,$divi)


#@code_warntype tf(time,divi)

#@test tf(time,divi)[1:4] == (2,3,4,5)


struct DateTime2{T,origintupe}
    instant::T
end

_origintuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)

function DateTime2(t,units::AbstractString)
    origintuple, base = timeunits(Tuple,units)

    instant = Period(t,base)
    dt = DateTime2{typeof(instant),Val(origintuple)}(instant)
end

function datetuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple}
    base = _base(dt.instant)
    denom = _denom(dt.instant)
    y,m,d,HMS... = _origintuple(dt)

    p = Period(
        (CFTime.datenum_gregjulian(y,m,d,true,false),HMS...),
        base,denom)

    p2 = Period(p.duration
                + (dt.instant.duration)
                ,base,denom)

    days,HMS... = timetuplefrac(p2)
    y, m, d = datetuple_ymd(DateTimeStandard,days)


    tt = (y, m, d, HMS...)
    return tt
end


function same_tuple(t1,t2)
    len = min(length(t1),length(t2))
     (t1[1:len] == t2[1:len]) &&
         all(==(0),t1[len+1:end]) &&
         all(==(0),t2[len+1:end])
end

dt = DateTime2(1000,"milliseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1), datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01T23:59:59")
@test same_tuple((2000, 1, 2), datetuple(dt))

dt = DateTime2(1,"microseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 0, 0, 1),datetuple(dt))
