using Pkg

Pkg.activate("CFTime-env",shared=true)

using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple, datenum, AbstractCFDateTime, parseDT
import Dates
import Dates: year,  month,  day, hour, minute, second, millisecond
using Test
using BenchmarkTools
import Base: +, -, *
using Dates


# all supported time units, e.g.
# a day is 24*60*60*1000/1 ms long
# a microsecond is 1/10^3  ms long
#
# The base unit is currently millisecond for compatability with the Julia
# Dates.DateTime type.
#
# We use a ratio of integers to avoid floating point rounding
# Int64 is used to avoid overflow on 32-bit for femtosecond and beyond

const TIME_DIVISION = (
    # name             numerator,   denominator
    (:day,         24*60*60*1000,             1),
    (:hour,           60*60*1000,             1),
    (:minute,            60*1000,             1),
    (:second,               1000,             1),
    (:millisecond,             1,             1),
    (:microsecond,             1,          10^3),
    (:nanosecond,              1,          10^6),
    (:picosecond,              1,          10^9),
    (:femtosecond,             1,  Int64(10)^12),
    (:attosecond,              1,  Int64(10)^15),
    (:zeptosecond,             1,  Int64(10)^18),
    (:yoctosecond,             1, Int128(10)^21),
)

unwrap(::Val{x}) where x = x


"""
if T is a integer
duration * numerator / denominator represents the time in milliseconds
"""
struct Period{T,numerator,denominator}
    duration::T
end


Period(duration::Number,numerator,denominator=1) = Period{typeof(duration),Val(numerator),Val(denominator)}(duration)

_numerator(p::Period{T,numerator,denominator}) where {T,numerator,denominator} = unwrap(numerator)
_denominator(p::Period{T,numerator,denominator}) where {T,numerator,denominator} = unwrap(denominator)

# sadly Dates.CompoundPeriod allocates a vector
#@btime Dates.CompoundPeriod(Dates.Day(1),Dates.Hour(1))

#Dates.CompoundPeriod(Dates.Day(1),Attosecond(1))


@inline __tf(result,time) = result
@inline function __tf(result,time,d1,dn...)
   if d1 == 0
       __tf((result...,0),0,dn...)
   else
#       p = fld(time, d1)
#       time2 = time - p*d1
       p, time2 = divrem(time, d1)
       __tf((result...,p),time2,dn...)
    end
end
@inline tf(time,divi) = __tf((),time,divi...)

# rescale the time units for the ratio numerator/denominator
@inline function division(numerator,denominator)
    (denominator .* getindex.(TIME_DIVISION,2)) .÷ (getindex.(TIME_DIVISION,3) .* numerator)
end

@inline function datenum_(tuf::Tuple,numerator,denominator)
    divi = division(numerator,denominator)
    return sum(divi[1:length(tuf)] .* tuf)
end

function timetuplefrac(t::Period{T,Tnumerator}) where {T,Tnumerator}
    # for integers
    numerator = _numerator(t)
    denominator = _denominator(t)
    divi = division(numerator,denominator)
    time = t.duration
    tf(time,divi)
end


function Period(tuf::Tuple,numerator,denominator=1)
    duration = datenum_(tuf,numerator,denominator)
    Period{typeof(duration),Val(numerator),Val(denominator)}(duration)
end

function Period(T::DataType,tuf::Tuple,numerator,denominator=1)
    duration = T(datenum_(tuf,numerator,denominator))
    Period{typeof(duration),Val(numerator),Val(denominator)}(duration)
end

#@code_warntype tf(time,divi)



@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5)*1000,1))[1:4] == (2,3,4,5)


@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5),1000))[1:4] == (2,3,4,5)

numerator = 1000

#for tuf in (
#    (2,3,4,5),
tuf=    (2,3,4,5,6,7,8)
#    )
numerator = 1e-6
denominator = 1

p = Period(tuf,numerator)
@test timetuplefrac(p)[1:length(tuf)] == tuf


numerator = 1
denominator = 10^6

p = Period(tuf,numerator,denominator)
@test timetuplefrac(p)[1:length(tuf)] == tuf


#end


@btime datenum_($tuf,$numerator,1)

#@btime tf($time,$divi)


#@code_warntype tf(time,divi)

#@test tf(time,divi)[1:4] == (2,3,4,5)


function _timeunits(::Type{DT},units) where DT
    tunit_mixedcase,starttime = strip.(split(units," since "))
    tunit = lowercase(tunit_mixedcase)

    t0 = parseDT(DT,starttime)

    # make sure that plength is 64-bit on 32-bit platforms
    # plength is duration is *milliseconds*
    plength =
        if (tunit == "years") || (tunit == "year")
            SOLAR_YEAR
        elseif (tunit == "months") || (tunit == "month")
            SOLAR_YEAR ÷ 12
        elseif (tunit == "days") || (tunit == "day")
            24*60*60*Int64(1000)
        elseif (tunit == "hours") || (tunit == "hour")
            60*60*Int64(1000)
        elseif (tunit == "minutes") || (tunit == "minute")
            60*Int64(1000)
        elseif (tunit == "seconds") || (tunit == "second")
            Int64(1000)
        elseif (tunit == "milliseconds") || (tunit == "millisecond")
            Int64(1)
        elseif (tunit == "microseconds") || (tunit == "microsecond")
            1//Int64(10)^3
        elseif (tunit == "nanoseconds") || (tunit == "nanosecond")
            1//Int64(10)^6
        elseif (tunit == "picoseconds") || (tunit == "picosecond")
            1//Int64(10)^9
        elseif (tunit == "femtoseconds") || (tunit == "femtosecond")
            1//Int64(10)^12
        elseif (tunit == "attoseconds") || (tunit == "attosecond")
            1//Int64(10)^15
        else
            error("unknown units \"$(tunit)\"")
        end

    return t0,plength
end


struct DateTime2{T,origintupe} <: AbstractCFDateTime
    instant::T
end

_origintuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)

function DateTime2(t,units::AbstractString)
    origintuple, ratio = _timeunits(Tuple,units)
    instant = Period(t,Base.numerator(ratio),Base.denominator(ratio))
    dt = DateTime2{typeof(instant),Val(origintuple)}(instant)
end

_pad3(a::Tuple{T1}) where T1 = (a[1],0,0)
_pad3(a::Tuple{T1,T2})  where {T1,T2}  = (a[1],a[2],0)
_pad3(a::Tuple) = a

function DateTime2(T::DataType,
    args...;
    origin = (1970, 1, 1),
    unit = first(TIME_DIVISION[max(length(args),7)-2]), # milliseconds or smaller
    )

    y,m,d,HMS... = _pad3(args)
    oy,om,od,oHMS... = _pad3(origin)

    numerator, denominator = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    # time origin
    p = Period(T,
        (datenum(DateTimeStandard,y,m,d),HMS...),
        numerator,
        denominator) -
            Period(T,
        (datenum(DateTimeStandard,oy,om,od),oHMS...),
        numerator,
                   denominator)

    return DateTime2{typeof(p),Val(origin)}(p)
end

DateTime2(y::Integer,args::Vararg{<:Number,N}; kwargs...) where N = DateTime2(Int64,y,args...; kwargs...)

function datetuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple}
    numerator = _numerator(dt.instant)
    denominator = _denominator(dt.instant)
    y,m,d,HMS... = _origintuple(dt)

    # time origin
    p = Period(
        (datenum(DateTimeStandard,y,m,d),HMS...),
        numerator,
        denominator)

    # add duration to time origin
    p2 = Period(
        p.duration + dt.instant.duration,
        numerator,
        denominator)

    # HMS contains hours, minutes, seconds and all sub-second units
    days,HMS... = timetuplefrac(p2)
    y, m, d = datetuple_ymd(DateTimeStandard,days)

    return (y, m, d, HMS...)
end



for (i,(name,numerator,denominator)) in enumerate(TIME_DIVISION)
    function_name = Symbol(uppercasefirst(String(name)))

    @eval begin
        function $function_name(d::T) where T <: Number
            Period{T,$(Val(numerator)),$(Val(denominator))}(d)
        end

        @inline function $function_name(dt::T) where T <: DateTime2
            datetuple(dt)[$(i+2)] # years and months are special
        end
    end
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
@test Day(dt) == 2
@test Second(dt) == 0
@test Millisecond(dt) == 0
@test Microsecond(dt) == 0


dt = DateTime2(1,"microseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 0, 0, 1),datetuple(dt))




function +(p1::Period{T,Tnumerator,Tdenominator},p2::Period{T,Tnumerator,Tdenominator}) where {T, Tnumerator, Tdenominator}
    Period{T,Tnumerator,Tdenominator}(p1.duration + p2.duration)
end

function +(p1::Period{T1},p2::Period{T2}) where {T1, T2}
    T = promote_type(T1,T2)

    if _numerator(p1) / _denominator(p1) < _numerator(p2) / _denominator(p2)

        duration = T(p1.duration) +
                       (T(p2.duration) * _numerator(p2) * _denominator(p1)) ÷
                           (_denominator(p2) * _numerator(p1))
        return Period(duration,_numerator(p1),_denominator(p1))
    else
        return @inline p2 + p1
    end
end

+(dt::DateTime2{T,Torigintuple},p::T) where {T,Torigintuple} =
    DateTime2{T,Torigintuple}(dt.instant + p)


function -(p::Period{T,Tnumerator,Tdenominator}) where {T, Tnumerator, Tdenominator}
    Period{T,Tnumerator,Tdenominator}(-p.duration)
end

-(p1::Period,p2::Period) = p1 + (-p2)


p1 = Microsecond(1)
p2 = Microsecond(10)
@test p1+p2 == Microsecond(11)


p1 = Microsecond(1)
p2 = Nanosecond(10)
@test p1+p2 == Nanosecond(1010)


dt = DateTime2(1,"microseconds since 2000-01-01")
@test Microsecond(dt + Microsecond(1)) == 2

#dt + p1



dt = DateTime2(1,"milliseconds since 2000-01-01T23:59:59.999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(1,"microseconds since 2000-01-01T23:59:59.999999")
@test same_tuple((2000, 1, 2), datetuple(dt))

dt = DateTime2(1,"nanoseconds since 2000-01-01T23:59:59.999999999")
@test same_tuple((2000, 1, 2), datetuple(dt))


dt = DateTime2(2001,1,1)
@test same_tuple((2001, 1, 1), datetuple(dt))


dt = DateTime2(2001,1,1 , 1,2,3,   100,200,300, unit = :nanosecond)
@test same_tuple((2001, 1, 1, 1,2,3, 100,200,300), datetuple(dt))


dt = DateTime2(Float32(366*24*60*60*1000),"milliseconds since 2000-01-01")
@time datetuple(dt);


dt = DateTime2(Float32(24*60*60*1000),"milliseconds since 2000-01-01")

Dates.hour(dt) < 24

@which datetuple(dt)

p2 = Period{Float32, Val{1}(), Val{1}()}(4.453488f12)

eps(p2.duration)/1000/60

timetuplefrac(p2)


# dt = DateTime2(Float64(24*60*60*1000),"milliseconds since 2000-01-01")
# @time datetuple(dt);

# dt = DateTime2(24*60*60*1000,"milliseconds since 2000-01-01")
# @time datetuple(dt);


#dt2 = dt + Millisecond(10);
#dt2 = dt + Millisecond(10) +  Microsecond(20) + Nanosecond(30);
