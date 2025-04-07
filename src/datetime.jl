
# contructor of AbstractCFDateTime and methods with AbstractCFDateTime as
# first or main argument


unwrap(::Val{x}) where x = x

Dates.value(p::AbstractCFDateTime) = Dates.value(p.instant)

_origintuple(dt::AbstractCFDateTime{T,Torigintuple}) where {T,Torigintuple} = unwrap(Torigintuple)

for (name,factor,exponent) in TIME_DIVISION
    qname = Meta.quot(name)
    @eval begin
        _Tfactor(::Val{$qname}) = Val($factor)
        _Texponent(::Val{$qname}) = Val($exponent)
    end
end

for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]

    @eval begin
        function $CFDateTime{T,Torigintuple}(args::Vararg{Integer,N}) where {T,Torigintuple,N}

            DT = $CFDateTime
            factor = _factor(T)
            exponent = _exponent(T)
            Ti = _type(T)

            y,m,d,HMS... = Ti.(pad_ymd(args))
            oy,om,od,oHMS... = Ti.(pad_ymd(unwrap(Torigintuple)))

            p = Period(
                Ti,
                (datenum(DT,y,m,d),HMS...),
                factor,
                exponent)

            #@debug "period " p
            # time origin
            p0 = Period(
                Ti,
                (datenum(DT,oy,om,od),oHMS...),
                factor,
                exponent)
            #@debug "period of origin" p0

            Δ = p - p0
            #@debug "duration " Δ
            return DT{T,Torigintuple}(Δ)
        end

        """
    $($CFDateTime)([Ti::DataType], y, [m, d, h, mi, s, ms, ...], origin = (1900, 1, 1), units = ...) -> $($CFDateTime)

Construct a `$($CFDateTime)` type by year (`y`), month (`m`, default 1),
day (`d`, default 1), hour (`h`, default 0), minute (`mi`, default 0),
second (`s`, default 0), millisecond (`ms`, default 0), ....
Currently `attosecond` is the smallest supported time unit.

All arguments must be convertible to `Int64`.
`$($CFDateTime)` is a subtype of `AbstractCFDateTime`.

The date is stored a duration since the time `origin` (epoch) expressed as `milliseconds`
but smaller time units will be if necessary.

The netCDF CF calendars are defined in [the CF Standard](http://cfconventions.org/cf-conventions/cf-conventions.html#calendar).
This type implements the calendar defined as "$($calendar)".
        """
        @inline function $CFDateTime(Ti::DataType,
                             args...;
                             origin = (1900, 1, 1),
                             # milliseconds or smaller
                             units = first(TIME_DIVISION[max(length(args),7)-2]),
                                     )
            as_val(x::T) where T <: Val = x
            as_val(x) = Val(x)

            DT = $CFDateTime

            Torigin = as_val(origin)
            Tunits = as_val(units)
            Tfactor = _Tfactor(Tunits)
            Texponent = _Texponent(Tunits)

            T = Period{Ti,Tfactor, Texponent}
            return DT{T,Torigin}(args...)
        end

        function $CFDateTime(t::Union{Number,Tuple},units::AbstractString)
            origintuple, factor, exponent = _timeunits(Tuple,units)
            instant = Period(t,factor,exponent)
            origintuple3 = chop0(origintuple,3)
            dt = $CFDateTime{typeof(instant),Val(origintuple3)}(instant)
        end

        # @inline is important for type-stability
        @inline $CFDateTime(y::Integer,args::Vararg{Integer,N}; kwargs...) where N = $CFDateTime(Int64,y,args...; kwargs...)


        function $CFDateTime(p::Period,origintuple::Tuple)
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

            Δy,mo2 = fldmod(mo - 1, 12)
            mo2 = mo2 + 1
            y = y + Δy

            T = eltype(dt.instant.duration)
            p = Period(
                T,
                (datenum($CFDateTime,y,mo2,d),HMS...),
                factor,
                exponent)   -
                _origin_period(dt)
            return $CFDateTime(p,_origintuple(dt))
        end

        Base.zero(::Type{$CFDateTime}) = Millisecond(0)

        function _origin_period(dt::$CFDateTime{T,Torigintuple}) where {T,Torigintuple}
            Ti = _type(T)
            if Ti <: AbstractFloat
                Ti = Int64
            end
            y,m,d,HMS... = Ti.(_origintuple(dt))

            # factor and exponent can be different for the origin
            # in particular, there can be more resolution, for example
            # the unit "days since 2024-02-29 12:44:36"

            # -2: skip year and month
            _,factor,exponent = TIME_DIVISION[length(_origintuple(dt))-2]

            # time origin
            return Period(
                Ti,
                (datenum($CFDateTime,y,m,d),HMS...),
                factor,
                exponent)
        end

        @inline function _datetuple(dt::$CFDateTime)
            factor = _factor(dt.instant)
            exponent = _exponent(dt.instant)

            # time origin
            p = _origin_period(dt)
            # add duration to time origin
            p2 = p + dt.instant
            # HMS contains hours, minutes, seconds and all sub-second units
            days,HMS... = timetuplefrac(p2)
            y, m, d = datetuple_ymd($CFDateTime,days)
            return (y, m, d, HMS...)
        end

        function datetuple(dt::$CFDateTime)
            return chop0(_datetuple(dt),7)
        end

    end
end

function units(dt::AbstractCFDateTime{T,Torigintuple}) where {T,Torigintuple}
    return string(units(dt.instant)," since ",
                  format_datetuple(unwrap(Torigintuple)))
end

+(dt::AbstractCFDateTime,p::Union{Dates.TimePeriod,Dates.Day}) = dt + convert(CFTime.Period,p)

@inline function -(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    (_origin_period(dt1) - _origin_period(dt2)) + (dt1.instant - dt2.instant)
end

# fast case if the same resolution and time origin is used
@inline function -(dt1::DT,dt2::DT) where DT <: AbstractCFDateTime{T,Torigintuple} where {T,Torigintuple}
     dt1.instant - dt2.instant
end


function -(dt1::AbstractCFDateTime,dt2::DateTime)
    dt1 - convert(DateTimeProlepticGregorian,dt2)
end

function -(dt1::DateTime,dt2::AbstractCFDateTime)
    convert(DateTimeProlepticGregorian,dt1) - dt2
end

-(dt::AbstractCFDateTime,Δ::Period) = dt + (-Δ)
-(dt::AbstractCFDateTime,Δ::Dates.CompoundPeriod) = dt + (-Δ)
-(dt::AbstractCFDateTime,Δ) = dt + (-Δ)

function ==(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    return Dates.value(dt1 - dt2) == 0
end

function isless(dt1::AbstractCFDateTime,dt2::AbstractCFDateTime)
    return Dates.value(dt1 - dt2) < 0
end


pad_ymd(a::Tuple{T1}) where T1 = (a[1],1,1)
pad_ymd(a::Tuple{T1,T2})  where {T1,T2}  = (a[1],a[2],1)
pad_ymd(a::Tuple) = a

@inline function chop0(timetuple,minlen=0)
    if length(timetuple) == minlen
        return timetuple
    elseif timetuple[end] == 0
        return chop0(timetuple[1:end-1],minlen)
    else
        return timetuple
    end
end

function format_datetuple(timetuple::Tuple)
    y,mo,d,rest... = pad_ymd(timetuple)

    io = IOBuffer()
    @printf(io,"%04d-%02d-%02d",y,mo,d)

    if length(rest) > 0
        @printf(io,"T")

        for i = 1:3
            r,rest... = rest
            @printf(io,"%02d",r)
            if length(rest) == 0
                break
            end
            if i < 3
                @printf(io,":")
            end
        end

        if length(rest) > 0
            @printf(io,".")

            for subsec_ in rest
                @printf(io,"%03d",subsec_)
            end
        end
    end

    return String(take!(io))
end


function string(dt::T)  where T <: AbstractCFDateTime
    return format_datetuple(chop0(datetuple(dt),6))
end

function show(io::IO,dt::T)  where T <: AbstractCFDateTime
    println(io, string(typeof(dt).name.name), "(",string(dt),")")
end


# Missing support
(-)(x::AbstractCFDateTime, y::Missing) = missing
