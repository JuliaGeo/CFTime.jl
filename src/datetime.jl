# contructor of AbstractCFDateTime and methods with AbstractCFDateTime as
# first or main argument


unwrap(::Val{x}) where x = x

Dates.value(p::AbstractCFDateTime) = Dates.value(p.instant)

_origintuple(dt::AbstractCFDateTime{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)

for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]

    @eval begin
        function $CFDateTime{T,Torigintuple}(args::Vararg{<:Integer,N}) where {T,Torigintuple,N}

            DT = $CFDateTime
            y,m,d,HMS... = _pad3(args)
            oy,om,od,oHMS... = _pad3(unwrap(Torigintuple))

            factor = _factor(T)
            exponent = _exponent(T)
            Ti = _type(T)

            p = Period(
                Ti,
                (datenum(DT,y,m,d),HMS...),
                factor,
                exponent)

            # time origin
            p0 = Period(
                Ti,
                (datenum(DT,oy,om,od),oHMS...),
                factor,
                exponent)

            Δ = p - p0
            return DT{T,Torigintuple}(Δ)
        end

        """
    $($CFDateTime)([Ti::DataType], y, [m, d, h, mi, s, ms]) -> $($CFDateTime)

Construct a `$($CFDateTime)` type by year (`y`), month (`m`, default 1),
day (`d`, default 1), hour (`h`, default 0), minute (`mi`, default 0),
second (`s`, default 0), millisecond (`ms`, default 0).
All arguments must be convertible to `Int64`.
`$($CFDateTime)` is a subtype of `AbstractCFDateTime`.

The netCDF CF calendars are defined in [the CF Standard](http://cfconventions.org/cf-conventions/cf-conventions.html#calendar).
This type implements the calendar defined as "$($calendar)".
        """
        function $CFDateTime(Ti::DataType,
                             args...;
#                             origin = (1858,11,17),
                             origin = (1900, 1, 1),
                             # milliseconds or smaller
                             unit = first(TIME_DIVISION[max(length(args),7)-2]),
                             )
            DT = $CFDateTime
            factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]
            T = Period{Ti,Val(factor), Val(exponent)}
            return DT{T,Val(origin)}(args...)
        end

        function $CFDateTime(t,units::AbstractString)
            origintuple, factor, exponent = _timeunits(Tuple,units)
            instant = Period(t,factor,exponent)
            dt = $CFDateTime{typeof(instant),Val(origintuple)}(instant)
        end

        $CFDateTime(y::Integer,args::Vararg{<:Integer,N}; kwargs...) where N = $CFDateTime(Int64,y,args...; kwargs...)


        function $CFDateTime(p::Period,origintuple)
            $CFDateTime{typeof(p),Val(origintuple)}(p)
        end

        """
    $($CFDateTime)(dt::AbstractString, format::AbstractString; locale="english") -> $($CFDateTime)

Construct a $($CFDateTime) by parsing the `dt` date time string following the
pattern given in the `format` string.

!!! note
    This function is experimental and might
    be removed in the future. It relies on some internal function of `Dates` for
    parsing the `format`.
"""
        function $CFDateTime(dt::AbstractString, format::AbstractString; locale="english")
            return parse($CFDateTime, dt, DateFormat(format, locale))
        end

        $CFDateTime(dt::AbstractString, format::DateFormat) =
            parse($CFDateTime, dt, format)

        function +(dt::$CFDateTime,p::Period)
            p2 = dt.instant + p
            $CFDateTime(p2,_origintuple(dt))
        end

        function +(dt::$CFDateTime,Δ::Dates.Year)
            factor = _factor(dt.instant)
            exponent = _exponent(dt.instant)
            y,mo,d,HMS... = datetuple(dt)
            y2 = y + Dates.value(Δ)

            T = eltype(dt.instant.duration)
            p = Period(
                T,
                (datenum($CFDateTime,y2,mo,d),HMS...),
                factor,
                exponent)   -
                    _origin_period(dt)
            return $CFDateTime(p,_origintuple(dt))
        end

        function +(dt::$CFDateTime,Δ::Dates.Month)
            factor = _factor(dt.instant)
            exponent = _exponent(dt.instant)

            y,mo,d,HMS... = datetuple(dt)
            mo = mo + Dates.value(Δ)
            mo2 = mod(mo - 1, 12) + 1
            y = y + (mo-mo2) ÷ 12

            T = eltype(dt.instant.duration)
            p = Period(
                T,
                (datenum($CFDateTime,y,mo2,d),HMS...),
                factor,
                exponent)   -
                _origin_period(dt)
            return $CFDateTime(p,_origintuple(dt))
        end


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

            return chop0((y, m, d, HMS...),7)
        end

    end
end


function +(p1::Period{T,Tfactor,Texponent},p2::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(p1.duration + p2.duration)
end

function +(p1::Period{T1},p2::Period{T2}) where {T1, T2}
    T = promote_type(T1,T2)

    # which is the smallest unit?
    if _factor(p1) / 10^(-_exponent(p1)) < _factor(p2) / 10^(-_exponent(p2))

        duration = T(p1.duration) +
                       (T(p2.duration) * _factor(p2) * 10^(_exponent(p2)-_exponent(p1))) ÷
                       _factor(p1)
        return Period(duration,_factor(p1),_exponent(p1))
    else
        return @inline p2 + p1
    end
end


+(dt::AbstractCFDateTime,p::Union{Dates.TimePeriod,Dates.Day}) = dt + convert(CFTime.Period,p)

function -(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
     (_origin_period(dt1) - _origin_period(dt2)) + (dt1.instant - dt2.instant)
end

function -(dt1::AbstractCFDateTime,dt2::DateTime)
    dt1 - convert(DateTimeProlepticGregorian,dt2)
end

function -(dt1::DateTime,dt2::AbstractCFDateTime)
    convert(DateTimeProlepticGregorian,dt1) - dt2
end

-(dt::AbstractCFDateTime,Δ::Period) = dt + (-Δ)
-(dt::AbstractCFDateTime,Δ) = dt + (-Δ)

function ==(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    return Dates.value(dt1 - dt2) == 0
end

function isless(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    return Dates.value(dt1 - dt2) < 0
end


_pad3(a::Tuple{T1}) where T1 = (a[1],0,0)
_pad3(a::Tuple{T1,T2})  where {T1,T2}  = (a[1],a[2],0)
_pad3(a::Tuple) = a

function chop0(timetuple,minlen=0)
    if length(timetuple) == minlen
        return timetuple
    elseif timetuple[end] == 0
        return chop0(timetuple[1:end-1],minlen)
    else
        return timetuple
    end
end

function string(dt::T)  where T <: AbstractCFDateTime
    y,mo,d,h,mi,s,subsec... = chop0(datetuple(dt),6)
    io = IOBuffer()
    @printf(io,"%04d-%02d-%02dT%02d:%02d:%02d",y,mo,d,h,mi,s)
    if length(subsec) > 0
        @printf(io,".")
    end

    for subsec_ in subsec
        @printf(io,"%03d",subsec_)
    end

    return String(take!(io))
end

function show(io::IO,dt::T)  where T <: AbstractCFDateTime
    write(io, string(typeof(dt)), "(",string(dt),")")
end
