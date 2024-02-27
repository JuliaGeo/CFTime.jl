
# methods with Period as first argument

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



Period(duration::Number,factor,exponent=-3) = Period{typeof(duration),Val(factor),Val(exponent)}(duration)

_factor(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(factor)
_exponent(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(exponent)


function Base.zero(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(0)
end

function Base.one(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(1)
end


Dates.value(p::Period) = p.duration

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



+(p1::Period,p2::Dates.TimePeriod) = p1 + convert(Period,p2)


function -(p::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(-p.duration)
end

-(p1::Period,p2) = p1 + (-p2)


import Base: convert

for T in (:Hour, :Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
    local factor, exponent, unit
    unit = Symbol(lowercase(string(T)))
    factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    @eval convert(::Type{Period},t::Dates.$T) = Period{Int64,Val($factor),Val($exponent)}(Dates.value(t))
end


function ==(p1::Period,p2)
    return Dates.value(p1 - p2) == 0
end

function isless(p1::Period,p2::Period)
    return Dates.value(p1 - p2) < 0
end

# methods with AbstractCFDateTime as first argument


function isless(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    return Dates.value(dt1 - dt2) < 0
end

Dates.value(p::AbstractCFDateTime) = Dates.value(p.instant)

_origintuple(dt::AbstractCFDateTime{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)


_pad3(a::Tuple{T1}) where T1 = (a[1],0,0)
_pad3(a::Tuple{T1,T2})  where {T1,T2}  = (a[1],a[2],0)
_pad3(a::Tuple) = a

for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]

    @eval begin
        function _origin_period(dt::$CFDateTime)
            factor = _factor(dt.instant)
            exponent = _exponent(dt.instant)
            y,m,d,HMS... = _origintuple(dt)

            # time origin
            return Period(
                (datenum($CFDateTime,y,m,d),HMS...),
                factor,
                exponent)
        end

        function datetuple(dt::$CFDateTime)
            factor = _factor(dt.instant)
            exponent = _exponent(dt.instant)

            # time origin
            p = _origin_period(dt)

            # add duration to time origin
            p2 = Period(
                p.duration + dt.instant.duration,
                factor,
                exponent)

            # HMS contains hours, minutes, seconds and all sub-second units
            days,HMS... = timetuplefrac(p2)
            y, m, d = datetuple_ymd($CFDateTime,days)

            return (y, m, d, HMS...)
        end
    end
end




for (i,(name,factor,exponent)) in enumerate(TIME_DIVISION)
    function_name = Symbol(uppercasefirst(String(name)))

    @eval begin
        # function $function_name(d::T) where T <: Number
        #     Period{T,$(Val(factor)),$(Val(exponent))}(d)
        # end

        @inline function $function_name(dt::T) where T <: AbstractCFDateTime
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





+(dt::AbstractCFDateTime{T,Torigintuple},p::T) where {T,Torigintuple} =
    AbstractCFDateTime{T,Torigintuple}(dt.instant + p)


+(dt::AbstractCFDateTime,p::Dates.TimePeriod) = dt + convert(Period,p)



function -(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
     (_origin_period(dt1) - _origin_period(dt2)) + (dt1.instant - dt2.instant)
end
