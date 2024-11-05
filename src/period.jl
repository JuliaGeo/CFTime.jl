# Period constructors or methods with Period as first (or main) argument

# sadly Dates.CompoundPeriod allocates a vector otherwise
# Dates.CompoundPeriod could have been used instead of CFTime.Period

Period(duration::Number,factor,exponent=-3) = Period{typeof(duration),Val(factor),Val(exponent)}(duration)

@inline function Period(duration::T,units::Val) where T <: Number
    Tfactor = _Tfactor(units)
    Texponent = _Texponent(units)
    return Period{T,Tfactor,Texponent}(duration)
end

@inline function Period(duration::Number,units::Union{Symbol,AbstractString})
    return Period(duration,Val(Symbol(units)))
end

_type(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent} = T
_factor(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent} = unwrap(Tfactor)
_exponent(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent} = unwrap(Texponent)


_type(::Type{Period{T,Tfactor,Texponent}}) where {T,Tfactor,Texponent} = T
_factor(::Type{Period{T,Tfactor,Texponent}}) where {T,Tfactor,Texponent} = unwrap(Tfactor)
_exponent(::Type{Period{T,Tfactor,Texponent}}) where {T,Tfactor,Texponent} = unwrap(Texponent)

function Base.zero(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent}
    Period{T,Tfactor,Texponent}(0)
end

function Base.one(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent}
    Period{T,Tfactor,Texponent}(1)
end


Dates.value(p::Period) = p.duration

# helper functions for _timetuple
@inline __tf(result,time) = result
@inline function __tf(result,time,d1,dn...)
   if d1 == 0
       __tf((result...,0),0,dn...)
   else
       p, time2 = divrem(time, d1, RoundDown)
       __tf((result...,Int64(p)),time2,dn...)
    end
end

"""
    _timetuple(time,divi)

Recursively divides `time` into the tuple `divi`. For example

```julia
divi = (24*60*60,60*60,60,1)
_timetuple(1234567,divi)
# output
# (14, 6, 56, 7)
# 14 days, 6 hours, 56 minutes, 7 seconds
sum(_timetuple(1234567,divi) .* divi) == 1234567
# output
# true
```
"""
@inline function _timetuple(time,divi)
    __tf((),time,divi...)
end

# rescale the time units for the ratio factor/exponent
@inline function division(T,factor,exponent)
    (T(10)^(-exponent) .* getindex.(TIME_DIVISION,2)) .÷ (T(10) .^ (.- getindex.(TIME_DIVISION,3)) .* factor)
end

@inline function _datenum(tuf::Tuple,factor,exponent)
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
    _timetuple(time,divi)
end


function Period(tuf::Tuple,factor,exponent=-3)
    duration = _datenum(tuf,factor,exponent)
    Period{typeof(duration),Val(factor),Val(exponent)}(duration)
end

function Period(T::DataType,tuf::Tuple,factor,exponent=-3)
    duration = T(_datenum(tuf,factor,exponent))
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


@inline function convert(::Type{Period{T1,Tfactor1,Texponent1}},
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

for op in (:+,:-,:mod)
    @eval begin
        function $op(p1::Period{T,Tfactor,Texponent},p2::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
            Period{T,Tfactor,Texponent}($op(p1.duration,p2.duration))
        end
    end
end

for op in (:+,:-,:mod,:(==))
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
        convert(::Type{Period},t::Dates.$T) =
            Period{Int64,Val($factor),Val($exponent)}(Dates.value(t))

        function promote_rule(::Type{Period{T,Tfactor,Texponent}},
                      ::Type{Dates.$T}) where {T,Tfactor,Texponent}
            return promote_type(
                Period{T,Tfactor,Texponent},
                Period{Int64,Val($factor),Val($exponent)})
        end
    end
end


function units(p::Period{T,Tfactor,Texponent}) where {T,Tfactor,Texponent}

    for (name,factor,exponent) in TIME_DIVISION
        if (Val(factor) == Tfactor) && (Val(exponent) == Texponent)
            # always append s for plural
            return string(name,"s")
        end
    end

    return string(unwrap(Tfactor)," × 10^",unwrap(Texponent)," s")
end



function Base.show(io::IO,p::Period)
    exp = _exponent(p)
    fact = _factor(p)

    time_divisions = (
        (:solar_year,  SOLAR_YEAR,      -3),
        (:solar_month, SOLAR_YEAR ÷ 12, -3),
        TIME_DIVISION...)

    for (name,factor,exponent) in time_divisions
        if (fact == factor) && (exp == exponent)
            print(io,"$(p.duration) $name")
            if p.duration != 1
                print(io,"s")
            end
            return
        end
    end
    print(io,"$(p.duration * fact) ")
    if exp != 0
        print(io,"× 10^($(exp)) ")
    end
    print(io,"s")
end


# Can throw an InexactError
@inline Dates.Millisecond(p::Period{T, Val{1}(), Val{-3}()}) where T =
    Dates.Millisecond(Int64(p.duration))

@inline function Dates.Millisecond(p::Period)
    Dates.Millisecond(convert(Period{Int64,Val{1}(),Val{-3}()},p))
end

@inline function Dates.Second(p::Period)
    Dates.Second(convert(Period{Int64,Val{1}(),Val{0}()},p))
end

@inline function Dates.Second(p::Period{T,Val{1}(),Val{0}()}) where T
    Dates.Second(p.duration)
end

function isless(p1::Period,p2::Period)
    return Dates.value(p1 - p2) < 0
end

# Missing support
(==)(x::Period, y::Missing) = missing
(==)(x::Missing, y::Period) = missing
