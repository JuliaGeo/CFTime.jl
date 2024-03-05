# Period constructors or methods with Period as first (or main) argument

# sadly Dates.CompoundPeriod allocates a vector otherwise
# Dates.CompoundPeriod could have been used instead of CFTime.Period

Period(duration::Number,factor,exponent=-3) = Period{typeof(duration),Val(factor),Val(exponent)}(duration)

function Period(duration::Number,units::Union{Symbol,AbstractString})
    factor, exponent = filter(td -> td[1] == Symbol(units),TIME_DIVISION)[1][2:end]
    return Period(duration,factor,exponent)
end

_type(p::Period{T,factor,exponent}) where {T,factor,exponent} = T
_factor(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(factor)
_exponent(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(exponent)


_type(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = T
_factor(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = unwrap(factor)
_exponent(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = unwrap(exponent)

function Base.zero(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(0)
end

function Base.one(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(1)
end


Dates.value(p::Period) = p.duration

@inline __tf(result,time) = result
@inline function __tf(result,time,d1,dn...)
   if d1 == 0
       __tf((result...,0),0,dn...)
   else
       p, time2 = divrem(time, d1, RoundDown)
       __tf((result...,Int64(p)),time2,dn...)
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

"""
    days,h,mi,s,ms,... = timetuplefrac(t::Period)

Return a tuple with the number of whole days, hours (`h`), minutes (`mi`),
seconds (`s`) and millisecods (`ms`),... from the time period `t`.
"""
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

function promote_rule(::Type{Period{T1,Tfactor1,Texponent1}},
                      ::Type{Period{T2,Tfactor2,Texponent2}}) where
    {T1,Tfactor1,Texponent1,T2,Tfactor2,Texponent2}

    factor1 = unwrap(Tfactor1)
    factor2 = unwrap(Tfactor2)
    exponent1 = unwrap(Texponent1)
    exponent2 = unwrap(Texponent2)
    T = promote_type(T1,T2)

    # which is the smallest unit?
    if factor1 / 10^(-exponent1) <= factor2 / 10^(-exponent2)
        return Period{T,Tfactor1,Texponent1}
    else
        return Period{T,Tfactor2,Texponent2}
    end
end

for Tfactor1 in (SOLAR_YEAR, SOLAR_YEAR ÷ 12)
    @eval function promote_rule(::Type{Period{T1,Val($Tfactor1), Val(-3)}},
                                ::Type{Period{T2,Tfactor2,Texponent2}}) where
        {T1,T2,Tfactor2,Texponent2}
        return promote_rule(
            Period{T1,Val(1), Val(-3)},
            Period{T2,Tfactor2,Texponent2})
    end
end


function convert(::Type{Period{T1,Tfactor1,Texponent1}},
                 p::Period{T2,Tfactor2,Texponent2}) where
    {T1,Tfactor1,Texponent1,T2,Tfactor2,Texponent2}

    factor1 = unwrap(Tfactor1)
    factor2 = unwrap(Tfactor2)
    exponent1 = unwrap(Texponent1)
    exponent2 = unwrap(Texponent2)

    duration =
        if T1 <: AbstractFloat
            (T1(p.duration) * factor2 * 10^(exponent2-exponent1)) / factor1
        else
            (T1(p.duration) * factor2 * 10^(exponent2-exponent1)) ÷ factor1
        end

    return Period{T1,Tfactor1,Texponent1}(duration)
end

function convert(::Type{Period{T,Tfactor,Texponent}},t::Union{Dates.Day,Dates.TimePeriod}) where {T,Tfactor,Texponent}
    p = convert(Period,t)
    convert(Period{T,Tfactor,Texponent},p)
end

function ==(p1::Period{T,Tfactor,Texponent},p2::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    return p1.duration == p2.duration
end

for op in (:+,:-)
    @eval begin
        function $op(p1::Period{T,Tfactor,Texponent},p2::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
            Period{T,Tfactor,Texponent}($op(p1.duration,p2.duration))
        end
    end
end

for op in (:+,:-,:(==))
    @eval begin
        $op(p1::Period,p2::Period) = $op(promote(p1,p2)...)
        $op(p1::Period,p2::Dates.Period) = $op(promote(p1,p2)...)
        $op(p1::Dates.Period,p2::Period) = $op(promote(p1,p2)...)
    end
end

function -(p::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(-p.duration)
end


for T in (:Day, :Hour, :Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
    unit = Symbol(lowercase(string(T)))
    factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    @eval begin
        convert(::Type{CFTime.Period},t::Dates.$T) =
            Period{Int64,Val($factor),Val($exponent)}(Dates.value(t))

        function promote_rule(::Type{Period{T,Tfactor,Texponent}},
                      ::Type{Dates.$T}) where {T,Tfactor,Texponent}
            return promote_type(
                Period{T,Tfactor,Texponent},
                Period{Int64,Val($factor),Val($exponent)})
        end
    end
end

# Can throw an InexactError
Dates.Millisecond(p::CFTime.Period{T, Val{1}(), Val{-3}()}) where T =
    Dates.Millisecond(Int64(p.duration))

function isless(p1::Period,p2::Period)
    return Dates.value(p1 - p2) < 0
end


# Missing support
(==)(x::Period, y::Missing) = missing
(==)(x::Missing, y::Period) = missing
