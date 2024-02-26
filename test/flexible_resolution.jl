using Pkg

Pkg.activate("CFTime-env",shared=true)

using CFTime
import CFTime: timetuplefrac, datetuple_ymd, timeunits, datetuple, datenum, AbstractCFDateTime, parseDT
import Dates
import Dates: year,  month,  day, hour, minute, second, millisecond
using Test
using BenchmarkTools
import Base: +, -, *, zero, one, isless, rem, div, string, convert
using Dates


# all supported time units, e.g.
# a day is 24*60*60 s long
#
# The base unit is currently millisecond for compatability with the Julia
# Dates.DateTime type.
#

const TIME_DIVISION = (
    # name           factor, exponent
    (:day,         24*60*60,      0),
    (:hour,           60*60,      0),
    (:minute,            60,      0),
    (:second,             1,      0),
    (:millisecond,        1,     -3),
    (:microsecond,        1,     -6),
    (:nanosecond,         1,     -9),
    (:picosecond,         1,    -12),
    (:femtosecond,        1,    -15),
    (:attosecond,         1,    -18),
    (:zeptosecond,        1,    -21),
    (:yoctosecond,        1,    -24),
)

unwrap(::Val{x}) where x = x


"""
if T is a integer
duration * factor / exponent represents the time in milliseconds
"""
struct Period{T,factor,exponent}
    duration::T
end


Period(duration::Number,factor,exponent=-3) = Period{typeof(duration),Val(factor),Val(exponent)}(duration)

_factor(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(factor)
_exponent(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(exponent)


function Base.zero(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(0)
end

function Base.one(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(1)
end



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

# rescale the time units for the ratio factor/exponent
@inline function division(T,factor,exponent)
    (T(10)^(-exponent) .* getindex.(TIME_DIVISION,2)) .÷ (T(10) .^ (.- getindex.(TIME_DIVISION,3)) .* factor)
end

@inline function datenum_(tuf::Tuple,factor,exponent)
    T =  promote_type(typeof.(tuf)...)
    divi = division(T,factor,exponent)
    return sum(divi[1:length(tuf)] .* tuf)
end

function timetuplefrac(t::Period{T,Tfactor}) where {T,Tfactor}
    # for integers
    factor = _factor(t)
    exponent = _exponent(t)
    divi = division(T,factor,exponent)
    time = t.duration
    tf(time,divi)
end


function Period(tuf::Tuple,factor,exponent=-3)
    duration = datenum_(tuf,factor,exponent)
    Period{typeof(duration),Val(factor),Val(exponent)}(duration)
end

function Period(T::DataType,tuf::Tuple,factor,exponent=-3)
    duration = T(datenum_(tuf,factor,exponent))
    Period{typeof(duration),Val(factor),Val(exponent)}(duration)
end

function _timeunits(::Type{DT},units) where DT
    tunit_mixedcase,starttime = strip.(split(units," since "))
    tunit = lowercase(tunit_mixedcase)

    t0 = parseDT(DT,starttime)

    # make sure that plength is 64-bit on 32-bit platforms
    # plength is duration is *milliseconds*
    if (tunit == "years") || (tunit == "year")
         # SOLAR_YEAR is in ms
        return t0, SOLAR_YEAR, -3
    elseif (tunit == "months") || (tunit == "month")
        return t0, SOLAR_YEAR ÷ 12, -3
    else
        for (name,factor,exponent) in TIME_DIVISION
            if tunit == string(name,"s") || (tunit == string(name))
                return t0, factor, exponent
            end
        end
    end

    error("unknown units \"$(tunit)\"")
end


struct DateTime2{T,origintupe} <: AbstractCFDateTime
    instant::T
end

_origintuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)

function DateTime2(t,units::AbstractString)
    origintuple, factor, exponent = _timeunits(Tuple,units)
    instant = Period(t,factor,exponent)
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

    factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    # time origin
    p = Period(T,
        (datenum(DateTimeStandard,y,m,d),HMS...),
        factor,
        exponent) -
            Period(T,
        (datenum(DateTimeStandard,oy,om,od),oHMS...),
        factor,
                   exponent)

    return DateTime2{typeof(p),Val(origin)}(p)
end

DateTime2(y::Integer,args::Vararg{<:Number,N}; kwargs...) where N = DateTime2(Int64,y,args...; kwargs...)

function datetuple(dt::DateTime2{T,Torigintuple}) where {T,Torigintuple}
    factor = _factor(dt.instant)
    exponent = _exponent(dt.instant)
    y,m,d,HMS... = _origintuple(dt)

    # time origin
    p = Period(
        (datenum(DateTimeStandard,y,m,d),HMS...),
        factor,
        exponent)

    # add duration to time origin
    p2 = Period(
        p.duration + dt.instant.duration,
        factor,
        exponent)

    # HMS contains hours, minutes, seconds and all sub-second units
    days,HMS... = timetuplefrac(p2)
    y, m, d = datetuple_ymd(DateTimeStandard,days)

    return (y, m, d, HMS...)
end



for (i,(name,factor,exponent)) in enumerate(TIME_DIVISION)
    function_name = Symbol(uppercasefirst(String(name)))

    @eval begin
        # function $function_name(d::T) where T <: Number
        #     Period{T,$(Val(factor)),$(Val(exponent))}(d)
        # end

        @inline function $function_name(dt::T) where T <: DateTime2
            datetuple(dt)[$(i+2)] # years and months are special
        end
    end
end


function +(p1::Period{T,Tfactor,Texponent},p2::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(p1.duration + p2.duration)
end

function +(p1::Period{T1},p2::Period{T2}) where {T1, T2}
    T = promote_type(T1,T2)

    # which is the smallest unit
    if _factor(p1) / 10^(-_exponent(p1)) < _factor(p2) / 10^(-_exponent(p2))

        duration = T(p1.duration) +
                       (T(p2.duration) * _factor(p2) * 10^(_exponent(p2)-_exponent(p1))) ÷
                       _factor(p1)
        return Period(duration,_factor(p1),_exponent(p1))
    else
        return @inline p2 + p1
    end
end


import Base: convert

for T in (:Hour, :Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
    unit = Symbol(lowercase(string(T)))
    factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    @eval convert(::Type{Period},t::Dates.$T) = Period{Int64,Val($factor),Val($exponent)}(Dates.value(t))
end



+(dt::DateTime2{T,Torigintuple},p::T) where {T,Torigintuple} =
    DateTime2{T,Torigintuple}(dt.instant + p)

function +(dt::DateTime2{T,Torigintuple},p::Period) where {T,Torigintuple}
    p2 = dt.instant + p
    DateTime2{typeof(p2),Torigintuple}(p2)
end

+(dt::DateTime2,p::Dates.TimePeriod) = dt + convert(Period,p)
+(p1::Period,p2::Dates.TimePeriod) = p1 + convert(Period,p2)


function -(p::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(-p.duration)
end

-(p1::Period,p2::Period) = p1 + (-p2)


function _origin_period(dt::DateTime2)
end

# function -(dt1::DateTime2,dt2::DateTime2)
#     y1,m1,d1,HMS1... = _origintuple(dt1)

#     # time origin
#     op1 = Period(
#         (datenum(DateTimeStandard,y,m,d),HMS...),
#         factor,
#         exponent)

#     p = dt2 - dt1
#     p2 = dt.instant + p
#     DateTime2{typeof(p2),Torigintuple}(p2)
# end


# TEST


function same_tuple(t1,t2)
    len = min(length(t1),length(t2))
     (t1[1:len] == t2[1:len]) &&
         all(==(0),t1[len+1:end]) &&
         all(==(0),t2[len+1:end])
end



@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5)*1000,1))[1:4] == (2,3,4,5)

@test timetuplefrac(Period((2*24*60*60  + 3*60*60 + 4*60  + 5),1000))[1:4] == (2,3,4,5)

factor = 1000

#for tuf in (
#    (2,3,4,5),
tuf=    (2,3,4,5,6,7,8)
#    )
factor = 1e-6
exponent = -3

p = Period(tuf,factor)
@test timetuplefrac(p)[1:length(tuf)] == tuf


factor = 1
exponent = -9

p = Period(tuf,factor,exponent)
@test timetuplefrac(p)[1:length(tuf)] == tuf


#end


@btime datenum_($tuf,$factor,0)

#@btime tf($time,$divi)


#@code_warntype tf(time,divi)

#@test tf(time,divi)[1:4] == (2,3,4,5)



dt = DateTime2(1000,"milliseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(1,"seconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 1),datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01");
@test same_tuple((2000, 1, 1, 0, 0, 1), datetuple(dt))

dt = DateTime2(10^9,"nanoseconds since 2000-01-01T23:59:59")
@test same_tuple((2000, 1, 2), datetuple(dt))
@test Day(dt) == 2
@test Second(dt) == 0
@test Millisecond(dt) == 0
@test Microsecond(dt) == 0


dt = DateTime2(1,"microseconds since 2000-01-01")
@test same_tuple((2000, 1, 1, 0, 0, 0, 0, 1),datetuple(dt))





# p1 = Microsecond(1)
# p2 = Microsecond(10)
# @test p1+p2 == Microsecond(11)


# p1 = Microsecond(1)
# p2 = Nanosecond(10)
# @test p1+p2 == Nanosecond(1010)




dt = DateTime2(1,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Microsecond(1)) == 2

@test Dates.nanosecond(dt) == 0

@test Dates.nanosecond(dt + Dates.Nanosecond(1)) == 1
@test Dates.nanosecond(dt + Dates.Nanosecond(1000)) == 0

dt = DateTime2(0,"microseconds since 2000-01-01")
@test Dates.microsecond(dt + Dates.Nanosecond(1000)) == 1




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

@test Dates.hour(dt) < 24
@test Dates.minute(dt) < 60
@test Dates.second(dt) < 60

@which datetuple(dt)



# dt = DateTime2(Float64(24*60*60*1000),"milliseconds since 2000-01-01")
# @time datetuple(dt);

# dt = DateTime2(24*60*60*1000,"milliseconds since 2000-01-01")
# @time datetuple(dt);


#dt2 = dt + Millisecond(10);
#dt2 = dt + Millisecond(10) +  Microsecond(20) + Nanosecond(30);

dt1 = DateTime2(0,"microseconds since 2000-01-01")
dt2 = DateTime2(10,"microseconds since 2000-01-01")


# dt1 == dt2

# dt1-dt2
#=
dr = dt1:Dates.Microsecond(2):dt2;
#first(dr)
#@which length(dr)
length(dr)

dt2 - dt1 

(dt2 - dt1) % Microsecond(2)

import Dates
dr = Dates.DateTime(2000,1,1):Dates.Day(1):Dates.DateTime(2000,1,1)
=#
