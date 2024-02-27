abstract type AbstractCFDateTime{T,Torigintuple} <: Dates.TimeType
end

const RegTime = Union{Dates.Millisecond,Dates.Second,Dates.Minute,Dates.Hour,Dates.Day}



"""
Period wraps a number of type T.

duration * factor * 10^exponent

represents the time in seconds
"""
struct Period{T,factor,exponent}
    duration::T
end


for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]
    @eval begin
        # struct $CFDateTime <: AbstractCFDateTime
        #     instant::UTInstant{Millisecond}
        #     $CFDateTime(instant::UTInstant{Millisecond}) = new(instant)
        # end
        struct $CFDateTime{T,Torigintuple} <: AbstractCFDateTime{T,Torigintuple}
            instant::T
        end

        function $CFDateTime(T::DataType,
                             args...;
                             origin = (1970, 1, 1),
                             # milliseconds or smaller
                             unit = first(TIME_DIVISION[max(length(args),7)-2]),
                             )

            y,m,d,HMS... = _pad3(args)
            oy,om,od,oHMS... = _pad3(origin)

            factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

            # time origin
            p = Period(
                T,
                (datenum(DateTimeStandard,y,m,d),HMS...),
                factor,
                exponent) -
                    Period(
                        T,
                        (datenum(DateTimeStandard,oy,om,od),oHMS...),
                        factor,
                        exponent)

            return $CFDateTime{typeof(p),Val(origin)}(p)
        end

        function $CFDateTime(t,units::AbstractString)
            origintuple, factor, exponent = _timeunits(Tuple,units)
            instant = Period(t,factor,exponent)
            dt = $CFDateTime{typeof(instant),Val(origintuple)}(instant)
        end

        $CFDateTime(y::Integer,args::Vararg{<:Number,N}; kwargs...) where N = $CFDateTime(Int64,y,args...; kwargs...)


        function $CFDateTime(p::Period,origintuple)
            DateTimeStandard{typeof(p),Val(origintuple)}(p)
        end
    end
end
