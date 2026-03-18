"""
    dtr = round(::Type{DateTime}, dt::Union{DateTimeProlepticGregorian,DateTimeStandard,DateTimeJulian},r = RoundNearestTiesUp)

Round the date time `dt` to the nearest date time represenatable by julia's
[`DateTime`](https://docs.julialang.org/en/v1/stdlib/Dates/#Dates.DateTime) using the rounding mode `r` (either
[`RoundNearest`](https://docs.julialang.org/en/v1/base/math/#Base.Rounding.RoundNearest) (default),
[`RoundDown`](https://docs.julialang.org/en/v1/base/math/#Base.Rounding.RoundDown), or
[`RoundUp`](https://docs.julialang.org/en/v1/base/math/#Base.Rounding.RoundUp)).
"""
function Base.round(::Type{DateTime}, dt::DateTimeProlepticGregorian, r::RoundingMode = RoundNearest)
    function round_ms(t)
        t_ms =
        if 3 + _exponent(t) > 0
            t.duration * _factor(t) * 10^(3 + _exponent(t))
        else
            t.duration * _factor(t) / 10^(-3 - _exponent(t))
        end

        t_ms_rounded =
        if t_ms isa Integer
            Int64(t_ms)
        else
            round(Int64, t_ms, r)
        end
        return Dates.Millisecond(t_ms_rounded)
    end

    origintuple = _origintuple(dt)
    origin = _origin_period(dt)

    if length(origintuple) >= 7
        # origin needs to be taken into account when rounding
        duration = round_ms(dt.instant + origin) + DATETIME_OFFSET
    else
        # better accuracy if dt.instant is a Float
        duration = round_ms(dt.instant) + origin + DATETIME_OFFSET
    end

    return DateTime(UTInstant{Millisecond}(Dates.Millisecond(duration)))
end

function Base.round(::Type{DateTime}, dt::Union{DateTimeJulian, DateTimeStandard}, r::RoundingMode = RoundNearest)
    return round(DateTime, convert(DateTimeProlepticGregorian, dt))
end

# see this discussion about changing the type parameters
# https://discourse.julialang.org/t/get-new-type-with-different-parameter/37253

for CFDateTime in (
        DateTimeStandard, DateTimeProlepticGregorian, DateTimeJulian,
        DateTimeNoLeap, DateTimeAllLeap, DateTime360Day,
    )
    @eval function Base.floor(dt::$CFDateTime, p::Period)
        origintuple = _origintuple(dt)
        origin = _origin_period(dt)
        t = dt.instant + origin
        t_mod = (t - mod(t, p)) - origin
        return $CFDateTime{typeof(t_mod), Val(origintuple)}(t_mod)
    end
end

function Base.floor(dt::AbstractCFDateTime, p::Dates.TimePeriod)
    return floor(dt, convert(Period, p))
end

function _floor(p, precision::TP) where {TP}
    return TP(p - mod(p, precision))
end

function _ceil(p, precision)
    f = floor(p, precision)
    return (f == p ? f : f + precision)
end


function _round(p, precision, ::RoundingMode{:NearestTiesUp})
    f = floor(p, precision)
    c = ceil(p, precision)
    if p - f < c - p
        return f
    else
        return c
    end
end

_round(p, precision) = _round(p, precision, RoundNearestTiesUp)

# fix ambiguities and avoid type-piracy

for fun in (:ceil, :floor, :round)
    _fun = Symbol(string('_', fun))
    @eval begin
        Base.$fun(p::Period, precision::Union{Period, Dates.Period}) = $_fun(p, precision)
        Base.$fun(p::Union{Period, Dates.Period}, precision::Period) = $_fun(p, precision)
        Base.$fun(p::Period, precision::Period) = $_fun(p, precision)


        Base.$fun(p::Period, precision::Type{T}) where {T <: Union{Period, Dates.Period}} = $_fun(p, precision)
        Base.$fun(p::Union{Period, Dates.Period}, precision::Type{T}) where {T <: Period} = $_fun(p, precision)
        Base.$fun(p::Period, precision::Type{T}) where {T <: Period} = $_fun(p, precision)
    end
end

for fun in (:ceil, :floor, :round)
    _fun = Symbol(string('_', fun))
    @eval begin
        function $_fun(p::Union{Period, Dates.Period}, ::Type{T}) where {T <: Union{Period, Dates.Period}}
            return $_fun(p, oneunit(T))
        end
    end
end

function Base.round(p::Union{Period, Dates.Period}, precision::Period, r::RoundingMode{:NearestTiesUp})
    return _round(p, precision, r)
end

function Base.round(p::Period, precision::Union{Period, Dates.Period}, r::RoundingMode{:NearestTiesUp})
    return _round(p, precision, r)
end

function Base.round(p::Period, precision::Period, r::RoundingMode{:NearestTiesUp})
    return _round(p, precision, r)
end
